class CreateVideoClips < ActiveRecord::Migration[6.0]
  def change
    create_table :video_clips do |t|
      t.text :title
      t.text :youtube_id
      t.references :song, foreign_key: true
      t.references :composer, foreign_key: true

      t.timestamps
    end
  end
end
