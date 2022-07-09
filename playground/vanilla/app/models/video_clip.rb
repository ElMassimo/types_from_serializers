class VideoClip < ApplicationRecord
  belongs_to :song
  has_one :composer, through: :song

  def youtube_url
    "https://www.youtube.com/watch?v=#{youtube_id}" if youtube_id
  end
end
