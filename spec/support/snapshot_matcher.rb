# frozen_string_literal: true

require "fileutils"

RSpec::Matchers.define :match_snapshot do |name|
  snapshot_dir = File.expand_path("../types_from_serializers/__snapshots__", __dir__)
  snapshot_path = File.join(snapshot_dir, "#{name}.snap")

  normalize = ->(content) { content.gsub(%r{^// TypesFromSerializers CacheKey .*\n}, "") }

  match do |actual|
    if ENV["UPDATE_SNAPSHOTS"] == "1"
      FileUtils.mkdir_p(snapshot_dir)
      File.write(snapshot_path, actual)
      true
    elsif File.exist?(snapshot_path)
      @expected = File.read(snapshot_path)
      values_match?(normalize.call(@expected), normalize.call(actual))
    else
      @expected = nil
      false
    end
  end

  failure_message do |actual|
    if @expected.nil?
      "Expected snapshot to exist: #{snapshot_path}. Run with UPDATE_SNAPSHOTS=1 to create it."
    else
      "Snapshot mismatch for #{snapshot_path}\n" \
        "expected:\n#{@expected}\n" \
        "got:\n#{actual}"
    end
  end
end
