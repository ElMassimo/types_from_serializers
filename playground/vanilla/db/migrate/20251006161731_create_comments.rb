class CreateComments < ActiveRecord::Migration[6.0]
  def change
    create_table :comments do |t|
      t.text :content
      t.text :author_name
      t.integer :parent_id

      t.timestamps
    end

    add_index :comments, :parent_id
  end
end
