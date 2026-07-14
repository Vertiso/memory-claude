# Copyright © 2026. Copyright Vertiso Corporation, all rights reserved.

require "json"
require "net/http"
require "openssl"
require "uri"
# pathname and timeout are only loaded transitively (via net/http) upstream;
# the constants they define (Pathname, Timeout::Error) must resolve on the
# older system Rubies the public plugin repos' CI runs (ubuntu-latest, Ruby
# 3.2), so require them explicitly. Lint/RedundantRequireStatement flags only
# `pathname` as redundant at this repo's TargetRubyVersion (4.0); it is not
# redundant downstream — hence the trailing disable on that line alone.
require "pathname" # rubocop:disable Lint/RedundantRequireStatement
require "timeout"

# Credential-free liveness check for the MCP endpoint a published Vertiso
# Memory plugin advertises. Proves the endpoint is up, speaks MCP, exposes
# RFC 9728 / RFC 8414 OAuth discovery, and correctly challenges an
# unauthenticated connect — the exact path a reviewer installing the plugin
# takes. Standard-library only so the same check runs upstream and in the
# public mirrors. Never sends or logs a credential (there are none here).
class EndpointVerifier
  # Raised when the advertised endpoint violates the publication contract.
  class Error < StandardError
  end

  # Marker for a retryable upstream blip (5xx, connection reset, timeout).
  class TransientError < StandardError
  end

  # Normalized HTTP response with case-insensitive header lookup so the real
  # and fake requesters present an identical surface. A frozen value object:
  # all three fields are mandatory at construction and have no public setters.
  Response = Data.define(:status, :body, :raw_headers) do
    # @param name [String] header name (case-insensitive)
    # @return [String, nil] joined header value or nil when absent
    def header(name)
      key = raw_headers.keys.find { |candidate| candidate.to_s.casecmp?(name) }
      return nil if key.nil?

      Array(raw_headers[key]).join(", ")
    end
  end

  # Real net/http collaborator: HTTPS, no redirect-following, per-request
  # timeout. Injected by default; a spec swaps in a deterministic double.
  class NetHttpRequester
    # @param method [Symbol] :get or :post
    # @param url [String] absolute request URL
    # @param body [String, nil] request body for :post
    # @return [Response]
    def request(method:, url:, body: nil)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = TIMEOUT_SECONDS
      http.read_timeout = TIMEOUT_SECONDS
      response = http.request(build_request(method:, uri:, body:))
      Response.new(
        status: response.code.to_i,
        body: response.body.to_s,
        raw_headers: response.to_hash
      )
    end

    private

    def build_request(method:, uri:, body:)
      case method
      when :get
        Net::HTTP::Get.new(uri)
      when :post
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["Accept"] = "application/json, text/event-stream"
        request.body = body
        request
      else
        raise Error, "unsupported HTTP method #{method.inspect}"
      end
    end
  end

  TIMEOUT_SECONDS = 10
  MAX_ATTEMPTS = 3
  BACKOFF_SECONDS = 0.5
  PROTECTED_RESOURCE_PATH = "/.well-known/oauth-protected-resource".freeze
  AUTHORIZATION_SERVER_PATH = "/.well-known/oauth-authorization-server".freeze
  MCP_CONFIG_PATH = "vertiso-memory/.mcp.json".freeze
  INITIALIZE_BODY = {
    jsonrpc: "2.0",
    id: 1,
    method: "initialize",
    params: {}
  }.freeze
  DEFAULT_SLEEPER = ->(seconds) { Kernel.sleep(seconds) }
  TRANSIENT_ERRORS = [
    TransientError,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::ETIMEDOUT,
    Errno::EHOSTUNREACH,
    SocketError,
    Net::OpenTimeout,
    Net::ReadTimeout,
    OpenSSL::SSL::SSLError,
    Timeout::Error
  ].freeze

  # @param root [Pathname, String] assembled public repository root
  # @param requester [#request] HTTP collaborator (injectable for tests)
  # @param sleeper [#call] backoff sleeper (injectable for tests)
  def initialize(
    root: ".",
    requester: NetHttpRequester.new,
    sleeper: DEFAULT_SLEEPER
  )
    @root = Pathname.new(root).expand_path
    @requester = requester
    @sleeper = sleeper
  end

  # Runs the full credential-free verification, printing an "ok" line per
  # passed check.
  # @return [String] the verified MCP url
  def call
    url = mcp_url
    origin = origin_for(url:)
    verify_discovery!(url:, origin:)
    verify_challenge!(url:, origin:)
    puts "ok endpoint verification passed"
    url
  end

  private

  attr_reader :root, :requester, :sleeper

  def mcp_url
    config = read_json(MCP_CONFIG_PATH)
    raise Error, "#{MCP_CONFIG_PATH} must be a JSON object" unless config.is_a?(Hash)

    server = config.fetch("mcpServers").fetch("vertiso-memory")
    url = server["url"].to_s.strip
    raise Error, "MCP url is missing in #{MCP_CONFIG_PATH}" if url.empty?
    raise Error, "MCP url must be https, got #{url.inspect}" unless url.start_with?("https://")

    puts "ok mcp url #{url}"
    url
  rescue KeyError
    raise Error, "#{MCP_CONFIG_PATH} is missing mcpServers.vertiso-memory"
  end

  def read_json(relative_path)
    JSON.parse(root.join(relative_path).read)
  rescue JSON::ParserError => e
    raise Error, "invalid JSON in #{relative_path}: #{e.message}"
  rescue Errno::ENOENT
    raise Error, "missing file: #{relative_path}"
  end

  def origin_for(url:)
    uri = URI.parse(url)
    default_port = uri.port == uri.default_port
    suffix = uri.port && !default_port ? ":#{uri.port}" : ""
    "#{uri.scheme}://#{uri.host}#{suffix}"
  rescue URI::InvalidURIError => e
    raise Error, "MCP url #{url.inspect} is not a parseable URI: #{e.message}"
  end

  def verify_discovery!(url:, origin:)
    resource_url = "#{origin}#{PROTECTED_RESOURCE_PATH}"
    resource = request_with_retry(method: :get, url: resource_url)
    assert_status!(response: resource, expected: 200, label: resource_url)
    assert_protected_resource_shape!(
      response: resource, url: resource_url, mcp_url: url, origin:
    )
    puts "ok protected-resource metadata 200"

    server_url = "#{origin}#{AUTHORIZATION_SERVER_PATH}"
    server = request_with_retry(method: :get, url: server_url)
    assert_status!(response: server, expected: 200, label: server_url)
    assert_authorization_server_shape!(
      response: server, url: server_url, origin:
    )
    puts "ok authorization-server metadata 200"
  end

  # Validates the RFC 9728 protected-resource document. Each invariant is
  # asserted separately so a failure names the exact key that broke. Beyond
  # well-formedness, the document must point back at THIS server: `resource`
  # equal to the advertised mcp url and `authorization_servers` including the
  # derived origin — so a server advertising another host's metadata fails.
  # @param mcp_url [String] the advertised MCP url this run verifies
  # @param origin [String] the origin derived from that url
  def assert_protected_resource_shape!(response:, url:, mcp_url:, origin:)
    document = parse_json_object!(response:, url:)

    resource = document["resource"]
    unless resource.is_a?(String) && !resource.strip.empty?
      raise Error, "#{url} is missing a nonempty String resource (RFC 9728)"
    end
    unless resource == mcp_url
      raise Error,
            "#{url} resource #{resource.inspect} must equal the advertised " \
            "mcp url #{mcp_url.inspect} (RFC 9728)"
    end

    servers = document["authorization_servers"]
    unless servers.is_a?(Array) && !servers.empty?
      raise Error,
            "#{url} is missing a non-empty authorization_servers Array " \
            "(RFC 9728)"
    end
    return if servers.include?(origin)

    raise Error,
          "#{url} authorization_servers #{servers.inspect} must include the " \
          "server origin #{origin.inspect} (RFC 9728)"
  end

  # Validates the RFC 8414 authorization-server metadata document. Symmetric
  # with the protected-resource check: parse, require a JSON object, then
  # assert each required endpoint key is a nonempty String, naming the url.
  # Also asserts the document describes THIS server: `issuer` equal to the
  # derived origin, and `code_challenge_methods_supported` an Array including
  # "S256" (PKCE S256 is mandatory for this OAuth setup per the runbook).
  # @param origin [String] the origin derived from the advertised mcp url
  def assert_authorization_server_shape!(response:, url:, origin:)
    document = parse_json_object!(response:, url:)

    %w[issuer authorization_endpoint token_endpoint].each do |key|
      value = document[key]
      next if value.is_a?(String) && !value.strip.empty?

      raise Error, "#{url} is missing a nonempty String #{key} (RFC 8414)"
    end

    issuer = document["issuer"]
    unless issuer == origin
      raise Error,
            "#{url} issuer #{issuer.inspect} must equal the server origin " \
            "#{origin.inspect} (RFC 8414)"
    end

    methods = document["code_challenge_methods_supported"]
    return if methods.is_a?(Array) && methods.include?("S256")

    raise Error,
          "#{url} code_challenge_methods_supported must be an Array " \
          "containing \"S256\" (PKCE S256 is mandatory)"
  end

  # Parses a metadata body and asserts it is a JSON object, wrapping bad JSON
  # into a named Error. Shared by both discovery shape checks.
  def parse_json_object!(response:, url:)
    document = JSON.parse(response.body)
    return document if document.is_a?(Hash)

    raise Error, "#{url} did not return a JSON object"
  rescue JSON::ParserError => e
    raise Error, "#{url} returned invalid JSON: #{e.message}"
  end

  def verify_challenge!(url:, origin:)
    response = request_with_retry(
      method: :post,
      url:,
      body: JSON.generate(INITIALIZE_BODY)
    )
    unless response.status == 401
      raise Error,
            "#{url} MCP initialize expected HTTP 401 challenge, " \
            "got #{response.status}"
    end

    assert_bearer_challenge!(response:, origin:)
    puts "ok mcp initialize challenged with 401 + resource_metadata"
  end

  def assert_bearer_challenge!(response:, origin:)
    challenge = response.header("WWW-Authenticate").to_s
    # RFC 7235 auth-scheme tokens are case-insensitive: accept "bearer" too.
    raise Error, "MCP 401 is missing a Bearer WWW-Authenticate challenge" unless challenge.match?(/\bBearer\b/i)

    resource_url = "#{origin}#{PROTECTED_RESOURCE_PATH}"
    pointed = challenge.include?("resource_metadata=") &&
              challenge.include?(resource_url)
    return if pointed

    raise Error,
          "MCP challenge must point resource_metadata at #{resource_url}"
  end

  def assert_status!(response:, expected:, label:)
    return if response.status == expected

    raise Error, "#{label} expected HTTP #{expected}, got #{response.status}"
  end

  def request_with_retry(method:, url:, body: nil)
    attempt = 0
    begin
      attempt += 1
      response = requester.request(method:, url:, body:)
      raise TransientError, "#{url} returned HTTP #{response.status}" if response.status >= 500

      response
    rescue *TRANSIENT_ERRORS => e
      if attempt >= MAX_ATTEMPTS
        raise Error,
              "#{url} unreachable after #{MAX_ATTEMPTS} attempts: #{e.message}"
      end

      sleeper.call(BACKOFF_SECONDS * attempt)
      retry
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    EndpointVerifier.new(root: ARGV.fetch(0, ".")).call
  rescue EndpointVerifier::Error => e
    warn "error: #{e.message}"
    exit 1
  end
end
