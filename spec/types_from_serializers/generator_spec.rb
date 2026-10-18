require "vanilla/config/boot"
require "vanilla/config/environment"

describe "Generator" do
  let(:output_dir) { Pathname.new File.expand_path("../support/generated", __dir__) }
  let(:sample_dir) { Rails.root.join("app/frontend/types/serializers") }
  let(:serializers) {
    %w[
      Nested::AlbumSerializer
      VideoWithSongSerializer
      VideoSerializer
      SongSerializer
      SongWithVideosSerializer
      ModelSerializer
      ComposerWithSongsSerializer
      ComposerWithSongsSerializer::SongSerializer
      ComposerSerializer
      SnakeComposerSerializer
      CommentSerializer
    ]
  }

  def file_for(dir, name, ext)
    dir.join("#{TypesFromSerializers.config.name_from_serializer.call(name).gsub("::", "/")}.#{ext}")
  end

  def app_file_for(name, ext = "ts")
    file_for(sample_dir, name, ext)
  end

  def output_file_for(name, ext = "ts")
    file_for(output_dir, name, ext)
  end

  def expect_generator
    expect(TypesFromSerializers)
  end

  def generate_serializers
    receive(:serializer_interface_content).and_call_original
  end

  original_config = TypesFromSerializers.config.to_h

  before do
    # Each example gets its own copy, so changes like `namespace` never leak.
    TypesFromSerializers.instance_variable_set(:@config, TypesFromSerializers::Config.new(original_config.transform_values(&:clone)))

    # Change the configuration to use a different directory.
    TypesFromSerializers.config do |config|
      config.output_dir = output_dir
    end

    output_dir.rmtree if output_dir.exist?
  end

  context "with default config options" do
    # NOTE: We do a manual snapshot test for now, more tests coming in the future.
    it "generates the files as expected" do
      TypesFromSerializers.generate

      # It generates one file per serializer, plus the index, and nothing else.
      index_file = output_dir.join("index.ts")
      expect(output_dir.glob("**/*.ts")).to match_array(serializers.map { |name| output_file_for(name) } + [index_file])

      serializers.each do |name|
        output_file = output_file_for(name)
        expect(output_file.read).to match_snapshot("interfaces_#{name.gsub("::", "__")}") # UPDATE_SNAPSHOTS="1" bin/rspec
      end

      # It generates an file that exports all interfaces.
      expect(index_file.read).to match_snapshot("interfaces_index") # UPDATE_SNAPSHOTS="1" bin/rspec

      # It does not write files whose content did not change.
      mtimes = output_dir.glob("**/*.ts").to_h { |file| [file, file.mtime] }
      TypesFromSerializers.generate
      expect(output_dir.glob("**/*.ts").to_h { |file| [file, file.mtime] }).to eq(mtimes)
    end

    it "rewrites files whose content no longer matches" do
      TypesFromSerializers.generate

      song_file = output_file_for("SongSerializer")
      song_file.write("// edited by hand\n")

      TypesFromSerializers.generate
      expect(song_file.read).to match_snapshot("interfaces_SongSerializer")
    end

    it "does not generate self-import for recursive serializers" do
      TypesFromSerializers.generate

      comment_file = output_file_for("CommentSerializer")
      content = comment_file.read

      # should not contain a self-import, but the properly and definition
      # should remain
      expect(content).not_to match(/import type Comment from ["']\.\/Comment["']/)
      expect(content).to match(/replies:\s*Comment\[\]/)
      expect(content).to match(/export default interface Comment/)
    end
  end

  context "with namespace config option" do
    it "generates the files as expected" do
      TypesFromSerializers.config do |config|
        config.namespace = "Schema"
      end

      expect_generator.to generate_serializers.exactly(serializers.size).times
      TypesFromSerializers.generate

      # It does not generate routes that don't have `export: true`.
      expect(output_file_for("BaseSerializer", "d.ts").exist?).to be false

      # It does not generate an index file
      index_file = output_dir.join("index.ts")
      expect(index_file.exist?).to be false

      # It generates one file per serializer.
      serializers.each do |name|
        output_file = output_file_for(name, "d.ts")
        expect(output_file.read).to match_snapshot("namespace_interfaces_#{name.gsub("::", "__")}") # UPDATE_SNAPSHOTS="1" bin/rspec
      end
    end
  end

  describe "generate_changed" do
    let(:song_serializer_file) { Rails.root.join("app/serializers/song_serializer.rb").to_s }

    def stub_changes(modified: [], added: [], removed: [])
      changes = instance_double(TypesFromSerializers::Changes,
        updated?: [modified, added, removed].any?(&:any?),
        only_modified?: added.empty? && removed.empty?,
        any_removed?: removed.any?,
        modified_files: Set.new(modified),
      )
      allow(TypesFromSerializers).to receive(:changes_for).and_return(changes)
      changes
    end

    it "does nothing when no serializer file changed" do
      stub_changes
      TypesFromSerializers.generate_changed
      expect(output_dir.exist?).to be false
    end

    it "regenerates interfaces but not the index when files were only modified" do
      changes = stub_changes(modified: [song_serializer_file])
      expect(changes).to receive(:clear)

      TypesFromSerializers.generate_changed
      expect(output_file_for("SongSerializer").read).to match_snapshot("interfaces_SongSerializer")
      expect(output_dir.join("index.ts").exist?).to be false
    end

    it "also loads the subclasses of a modified serializer, but not serializers that merely associate it" do
      changes = stub_changes(modified: [Rails.root.join("app/serializers/composer_serializer.rb").to_s])
      allow(changes).to receive(:clear)
      allow(TypesFromSerializers).to receive(:load_serializers).and_call_original

      TypesFromSerializers.generate_changed
      expect(TypesFromSerializers).to have_received(:load_serializers).with(array_including(
        Rails.root.join("app/serializers/snake_composer_serializer.rb").to_s,
        Rails.root.join("app/serializers/composer_with_songs_serializer.rb").to_s,
      ))
      expect(TypesFromSerializers).not_to have_received(:load_serializers).with(array_including(
        Rails.root.join("app/serializers/song_serializer.rb").to_s,
      ))
      expect(output_file_for("SnakeComposerSerializer").read).to match_snapshot("interfaces_SnakeComposerSerializer")
    end

    it "regenerates everything, dropping stale files, when a file was removed" do
      TypesFromSerializers.generate
      stale_file = output_dir.join("Removed.ts").tap { |file| file.write("stale") }
      changes = stub_changes(removed: [song_serializer_file])
      expect(changes).to receive(:clear)

      TypesFromSerializers.generate_changed
      expect(stale_file.exist?).to be false
      expect(output_dir.join("index.ts").read).to match_snapshot("interfaces_index")
    end
  end

  it "has a rake task available" do
    Rails.application.load_tasks
    expect_generator.to generate_serializers.exactly(serializers.size).times
    expect { Rake::Task["types_from_serializers:generate"].invoke }.not_to raise_error
  end

  describe "types mapping" do
    it "maps citext type from SQL to string type in TypeScript" do
      db_type = :citext

      ts_type = TypesFromSerializers.config.sql_to_typescript_type_mapping[db_type]

      expect(ts_type).to eq(:string)
    end

    it "maps uuid type from SQL to string type in TypeScript" do
      db_type = :uuid

      ts_type = TypesFromSerializers.config.sql_to_typescript_type_mapping[db_type]

      expect(ts_type).to eq(:string)
    end

    it "maps json type from SQL to object type in TypeScript" do
      db_type = :json

      ts_type = TypesFromSerializers.config.sql_to_typescript_type_mapping[db_type]

      expect(ts_type).to eq("Record<string, any>")
    end

    it "maps jsonb type from SQL to object type in TypeScript" do
      db_type = :jsonb

      ts_type = TypesFromSerializers.config.sql_to_typescript_type_mapping[db_type]

      expect(ts_type).to eq("Record<string, any>")
    end

    it "maps time type from SQL to string|Date type in typescript" do
      db_type = :time

      ts_type = TypesFromSerializers.config.sql_to_typescript_type_mapping[db_type]

      expect(ts_type).to eq("string | Date")
    end
  end
end
