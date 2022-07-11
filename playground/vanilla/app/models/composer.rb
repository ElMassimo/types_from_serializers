class Composer < ApplicationRecord
  has_many :songs
  has_many :video_clips, through: :songs

  def name
    [first_name, last_name].compact.join(" ")
  end
end
