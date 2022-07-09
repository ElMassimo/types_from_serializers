class CreateComposers < ActiveRecord::Migration[6.0]
  def change
    create_table :composers do |t|
      t.text :first_name
      t.text :last_name

      t.timestamps
    end
  end
end
