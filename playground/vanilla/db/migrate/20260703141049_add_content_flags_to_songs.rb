class AddContentFlagsToSongs < ActiveRecord::Migration[6.0]
  def change
    add_column :songs, :explicit_lyrics, :boolean, default: false
    add_column :songs, :vocal_track, :boolean, default: true
  end
end
