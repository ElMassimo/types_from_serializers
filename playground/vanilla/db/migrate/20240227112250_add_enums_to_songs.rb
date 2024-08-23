class AddEnumsToSongs < ActiveRecord::Migration[6.0]
  def change
    add_column :songs, :genre, :string, null: false
    add_column :songs, :tempo, :integer, null: true
  end
end
