class AddEnumsToComposers < ActiveRecord::Migration[6.0]
  def change
    add_column :composers, :genre, :string, null: false
    add_column :composers, :tempo, :integer, null: true
  end
end
