# Copyright © 2026. Copyright Vertiso Corporation, all rights reserved.

require "uri"
require "yaml"

# Validates Cursor manifests against the pinned official schema projection.
class CursorSchemaValidator
  # Raised when a manifest violates the pinned Cursor schema.
  class Error < StandardError
  end

  # Raised when the pinned schema itself is structurally unsupported
  # (unknown type, format, keyword, or unresolved reference). Distinct
  # from a document mismatch so `oneOf` matching never swallows it.
  class SchemaError < Error
  end

  PLUGIN_SCHEMA = "cursor-plugin.schema.yml".freeze
  MARKETPLACE_SCHEMA = "cursor-marketplace.schema.yml".freeze

  # Keywords that carry no validation semantics in this projection.
  # `source` / `checked_on` are the provenance block pinned atop each
  # schema file; the rest are standard JSON Schema annotations.
  ANNOTATION_KEYWORDS = %w[
    $comment
    $defs
    $id
    $schema
    checked_on
    default
    deprecated
    description
    examples
    source
    title
  ].freeze

  # Constraint keywords implemented per schema type. Anything outside
  # these lists (enum, minimum, patternProperties, ...) raises
  # SchemaError so schema drift never silently narrows coverage.
  TYPE_KEYWORDS = {
    "object"  => %w[additionalProperties properties required type],
    "array"   => %w[items type],
    "string"  => %w[format maxLength minLength pattern type],
    "boolean" => %w[type],
    "integer" => %w[type],
    "number"  => %w[type]
  }.freeze

  # @param schema_root [Pathname] directory containing the schema projections
  # @param plugin [Hash] parsed Cursor plugin manifest
  # @param marketplace [Hash] parsed Cursor marketplace catalog
  def initialize(schema_root:, plugin:, marketplace:)
    @schema_root = schema_root
    @plugin = plugin
    @marketplace = marketplace
  end

  # Validates both Cursor documents.
  # @return [CursorSchemaValidator] this validator
  # @raise [Error] when either document violates its schema
  def validate!
    validate_document!(
      value: plugin,
      schema: read_schema(PLUGIN_SCHEMA),
      label: "Cursor plugin"
    )
    validate_document!(
      value: marketplace,
      schema: read_schema(MARKETPLACE_SCHEMA),
      label: "Cursor marketplace"
    )
    self
  end

  private

  attr_reader :schema_root, :plugin, :marketplace

  def read_schema(filename)
    YAML.safe_load(schema_root.join(filename).read)
  rescue Errno::ENOENT, Psych::Exception => e
    raise Error, "invalid pinned Cursor schema #{filename}: #{e.message}"
  end

  def validate_document!(value:, schema:, label:)
    validate_value!(
      value:,
      schema:,
      root_schema: schema,
      label:
    )
  end

  def validate_value!(value:, schema:, root_schema:, label:)
    if schema.key?("$ref")
      assert_supported_keywords!(schema:, allowed: %w[$ref], label:)
      schema = resolve_ref(schema:, root_schema:)
    end
    if schema.key?("oneOf")
      assert_supported_keywords!(schema:, allowed: %w[oneOf], label:)
      return validate_one_of!(value:, schema:, root_schema:, label:)
    end

    type = schema.fetch("type", nil)
    allowed = TYPE_KEYWORDS.fetch(type) do
      raise SchemaError, "unsupported schema type #{type.inspect} for #{label}"
    end
    assert_supported_keywords!(schema:, allowed:, label:)
    case type
    when "object"
      validate_object!(value:, schema:, root_schema:, label:)
    when "array"
      validate_array!(value:, schema:, root_schema:, label:)
    when "string"
      validate_string!(value:, schema:, label:)
    when "boolean"
      validate_boolean!(value:, label:)
    when "integer"
      validate_integer!(value:, label:)
    when "number"
      validate_number!(value:, label:)
    end
  end

  def validate_one_of!(value:, schema:, root_schema:, label:)
    matches = schema.fetch("oneOf").count do |candidate|
      valid_against?(
        value:,
        schema: candidate,
        root_schema:,
        label:
      )
    end
    return if matches == 1

    raise Error, "#{label} must match exactly one allowed schema"
  end

  # True when the value matches the candidate schema. Only document
  # mismatches count as "no match"; SchemaError propagates so a broken
  # oneOf candidate fails the run instead of masquerading as a mismatch.
  def valid_against?(value:, schema:, root_schema:, label:)
    validate_value!(value:, schema:, root_schema:, label:)
    true
  rescue SchemaError
    raise
  rescue Error
    false
  end

  def assert_supported_keywords!(schema:, allowed:, label:)
    unknown = schema.keys - allowed - ANNOTATION_KEYWORDS
    return if unknown.empty?

    raise SchemaError,
          "unsupported schema keyword(s) #{unknown.join(', ')} for #{label}"
  end

  def validate_object!(value:, schema:, root_schema:, label:)
    raise Error, "#{label} must be an object" unless value.is_a?(Hash)

    properties = schema.fetch("properties", {})
    missing = schema.fetch("required", []) - value.keys
    raise Error, "#{label} is missing required fields: #{missing.join(', ')}" unless missing.empty?

    additional = schema.fetch("additionalProperties", nil)
    unless [ nil, true, false ].include?(additional)
      raise SchemaError,
            "unsupported additionalProperties schema for #{label}"
    end

    unsupported = value.keys - properties.keys
    raise Error, "unsupported #{label} fields: #{unsupported.join(', ')}" if additional == false && unsupported.any?

    properties.each do |key, child_schema|
      next unless value.key?(key)

      validate_value!(
        value: value.fetch(key),
        schema: child_schema,
        root_schema:,
        label: "#{label} #{key}"
      )
    end
  end

  def validate_array!(value:, schema:, root_schema:, label:)
    raise Error, "#{label} must be an array" unless value.is_a?(Array)

    item_schema = schema.fetch("items", nil)
    return if item_schema.nil?

    value.each_with_index do |item, index|
      validate_value!(
        value: item,
        schema: item_schema,
        root_schema:,
        label: "#{label}[#{index}]"
      )
    end
  end

  def validate_string!(value:, schema:, label:)
    raise Error, "#{label} must be a string" unless value.is_a?(String)

    minimum = schema.fetch("minLength", nil)
    raise Error, "#{label} must contain at least #{minimum} character" if minimum && value.length < minimum

    maximum = schema.fetch("maxLength", nil)
    raise Error, "#{label} must contain at most #{maximum} characters" if maximum && value.length > maximum

    pattern = schema.fetch("pattern", nil)
    raise Error, "#{label} does not match #{pattern}" if pattern && !value.match?(Regexp.new(pattern))

    validate_format!(value:, format: schema.fetch("format", nil), label:)
  end

  def validate_boolean!(value:, label:)
    return if [ true, false ].include?(value)

    raise Error, "#{label} must be a boolean"
  end

  def validate_integer!(value:, label:)
    raise Error, "#{label} must be an integer" unless value.is_a?(Integer)
  end

  def validate_number!(value:, label:)
    raise Error, "#{label} must be a number" unless value.is_a?(Numeric)
  end

  def validate_format!(value:, format:, label:)
    case format
    when nil
      nil
    when "email"
      return if value.match?(/\A[^@\s]+@[^@\s]+\z/)

      raise Error, "#{label} must be an email"
    when "uri"
      uri = URI.parse(value)
      return unless uri.scheme.to_s.empty?

      raise Error, "#{label} must be an absolute URI"
    else
      raise SchemaError, "unsupported schema format #{format.inspect} for #{label}"
    end
  rescue URI::InvalidURIError
    raise Error, "#{label} must be an absolute URI"
  end

  def resolve_ref(schema:, root_schema:)
    reference = schema.fetch("$ref")
    raise SchemaError, "unsupported external Cursor schema reference: #{reference}" unless reference.start_with?("#/")

    reference.delete_prefix("#/").split("/").reduce(root_schema) do |node, key|
      node.fetch(key.gsub("~1", "/").gsub("~0", "~"))
    end
  rescue KeyError
    raise SchemaError, "unresolved Cursor schema reference: #{reference}"
  end
end
