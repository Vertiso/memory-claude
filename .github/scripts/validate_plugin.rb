# Copyright © 2026. Copyright Vertiso Corporation, all rights reserved.

require "json"
# Explicit require: Pathname ships with the interpreter on Ruby >= 4.0
# but is require-gated on the older system Rubies the public plugin
# repos' CI runs (ubuntu-latest, Ruby 3.2). The cop reads this repo's
# TargetRubyVersion and calls it redundant; it is not, downstream.
require "pathname" # rubocop:disable Lint/RedundantRequireStatement
require "yaml"

require_relative "cursor_schema_validator"

# Validates a generated Vertiso Memory public plugin repository using only the
# Ruby standard library so the same check runs upstream and in public mirrors.
class PublicPluginValidator
  # Raised when a repository violates the publication contract.
  class Error < StandardError
  end

  VERSION_PATTERN = /\A(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\z/
  EXPECTED_SKILLS = %w[
    checkpoint
    handoff
    handoff-resume
    wrap-up
  ].freeze
  REQUIRED_ROOT_FILES = %w[
    LICENSE
    README.md
    SECURITY.md
    .github/ISSUE_TEMPLATE/bug_report.yml
    .github/ISSUE_TEMPLATE/config.yml
    .github/schemas/cursor-marketplace.schema.yml
    .github/schemas/cursor-plugin.schema.yml
    .github/scripts/validate_plugin.rb
    .github/scripts/cursor_schema_validator.rb
    .github/scripts/verify_endpoint.rb
    .github/workflows/validate.yml
  ].freeze
  REQUIRED_PAYLOAD_FILES = %w[
    .mcp.json
    CHANGELOG.md
    LICENSE
    README.md
  ].freeze
  STORE_CONFIG = {
    "claude" => {
      marketplace: ".claude-plugin/marketplace.json",
      plugin_manifest: "vertiso-memory/.claude-plugin/plugin.json",
      version_manifests: [ "vertiso-memory/.claude-plugin/plugin.json" ]
    },
    "cursor" => {
      marketplace: ".cursor-plugin/marketplace.json",
      plugin_manifest: "vertiso-memory/.cursor-plugin/plugin.json",
      version_manifests: [
        "vertiso-memory/.cursor-plugin/plugin.json",
        "vertiso-memory/.plugin/plugin.json"
      ]
    },
    "codex" => {
      marketplace: ".agents/plugins/marketplace.json",
      plugin_manifest: "vertiso-memory/.codex-plugin/plugin.json",
      version_manifests: [ "vertiso-memory/.codex-plugin/plugin.json" ]
    }
  }.freeze
  # @param root [Pathname, String] assembled public repository root
  def initialize(root:)
    @root = Pathname.new(root).expand_path
  end

  # Validates the complete public repository contract.
  # @return [String] detected store name
  def call
    store = detect_store
    config = STORE_CONFIG.fetch(store)
    assert_required_files!
    marketplace = read_json(config.fetch(:marketplace))
    plugin = read_json(config.fetch(:plugin_manifest))
    assert_marketplace!(store:, marketplace:)
    assert_plugin!(store:, plugin:)
    assert_versions!(config.fetch(:version_manifests))
    assert_mcp!
    assert_skills!
    assert_assets!(store:, plugin:)
    assert_cursor_schema!(marketplace:, plugin:) if store == "cursor"
    store
  end

  private

  attr_reader :root

  def detect_store
    matches = STORE_CONFIG.filter_map do |store, config|
      store if root.join(config.fetch(:marketplace)).file?
    end
    return matches.first if matches.one?

    raise Error, "expected exactly one supported marketplace, found #{matches.join(', ')}"
  end

  def assert_required_files!
    required = REQUIRED_ROOT_FILES + REQUIRED_PAYLOAD_FILES.map do |path|
      "vertiso-memory/#{path}"
    end
    missing = required.reject { |path| root.join(path).file? }
    return if missing.empty?

    raise Error, "missing required file: #{missing.join(', ')}"
  end

  def read_json(relative_path)
    JSON.parse(root.join(relative_path).read)
  rescue JSON::ParserError => e
    raise Error, "invalid JSON in #{relative_path}: #{e.message}"
  end

  def assert_marketplace!(store:, marketplace:)
    plugins = marketplace.fetch("plugins")
    raise Error, "marketplace must contain exactly one plugin" unless plugins.is_a?(Array) && plugins.one?

    entry = plugins.first
    raise Error, "marketplace plugin name must be vertiso-memory" unless entry["name"] == "vertiso-memory"

    source = entry.fetch("source")
    valid_source = source == expected_marketplace_source(store:)
    raise Error, "marketplace source must resolve ./vertiso-memory" unless valid_source
  rescue KeyError => e
    raise Error, "marketplace is missing #{e.key}"
  end

  def assert_plugin!(store:, plugin:)
    return if plugin["name"] == "vertiso-memory"

    raise Error, "#{store} plugin name must be vertiso-memory"
  end

  def expected_marketplace_source(store:)
    return "./vertiso-memory" unless store == "codex"

    {
      "source" => "local",
      "path" => "./vertiso-memory"
    }
  end

  def assert_versions!(manifest_paths)
    versions = manifest_paths.map do |path|
      version = read_json(path).fetch("version").to_s
      raise Error, "plugin version #{version.inspect} must use strict x.y.z" unless version.match?(VERSION_PATTERN)

      version
    end
    return if versions.uniq.one?

    raise Error, "version manifests disagree: #{versions.join(', ')}"
  rescue KeyError
    raise Error, "version manifest is missing version"
  end

  def assert_mcp!
    config = read_json("vertiso-memory/.mcp.json")
    server = config.fetch("mcpServers").fetch("vertiso-memory")
    return if server["url"] == "https://memory.vertiso.ai/mcp"

    raise Error, "Vertiso Memory MCP URL is invalid"
  rescue KeyError
    raise Error, "MCP config is missing mcpServers.vertiso-memory"
  end

  def assert_skills!
    skill_paths = root.glob("vertiso-memory/skills/*/SKILL.md")
    skill_names = skill_paths.map { |path| path.parent.basename.to_s }.sort
    raise Error, "skill set must be #{EXPECTED_SKILLS.sort.join(', ')}" unless skill_names == EXPECTED_SKILLS.sort

    skill_paths.each { |path| assert_skill_frontmatter!(path) }
  end

  def assert_skill_frontmatter!(path)
    match = path.read.match(/\A---\n(?<yaml>.*?)\n---(?:\n|\z)/m)
    raise Error, "invalid skill frontmatter in #{path}" if match.nil?

    metadata = YAML.safe_load(match[:yaml])
    expected_name = path.parent.basename.to_s
    valid = metadata.is_a?(Hash) && metadata["name"] == expected_name &&
            metadata["description"].is_a?(String) &&
            !metadata["description"].strip.empty?
    raise Error, "invalid skill frontmatter in #{path}" unless valid
  rescue Psych::Exception
    raise Error, "invalid skill frontmatter in #{path}"
  end

  def assert_assets!(store:, plugin:)
    paths = case store
            when "codex"
              interface = plugin.fetch("interface", {})
              [ interface["composerIcon"], interface["logo"] ] +
              Array(interface["screenshots"])
            when "cursor"
              [ plugin["logo"] ]
            else
              []
            end
    paths.compact.each { |path| assert_asset_path!(path) }
  end

  def assert_asset_path!(relative_path)
    normalized = relative_path.delete_prefix("./")
    path = root.join("vertiso-memory", normalized).cleanpath
    plugin_root = root.join("vertiso-memory").cleanpath
    inside_plugin = path.to_s.start_with?("#{plugin_root}/")
    return if inside_plugin && path.file?

    raise Error, "referenced asset is missing or unsafe: #{relative_path}"
  end

  def assert_cursor_schema!(marketplace:, plugin:)
    CursorSchemaValidator.new(
      schema_root: root.join(".github/schemas"),
      plugin:,
      marketplace:
    ).validate!
    compatibility = read_json("vertiso-memory/.plugin/plugin.json")
    return if compatibility == plugin

    raise Error, "Cursor compatibility plugin manifest differs from native manifest"
  rescue CursorSchemaValidator::Error => e
    raise Error, e.message
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    store = PublicPluginValidator.new(
      root: ARGV.fetch(0, Dir.pwd)
    ).call
    puts "ok #{store} public plugin repository"
  rescue PublicPluginValidator::Error, KeyError, Errno::ENOENT => e
    warn "error: #{e.message}"
    exit 1
  end
end
