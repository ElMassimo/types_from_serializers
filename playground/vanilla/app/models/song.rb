class Song < ApplicationRecord
  belongs_to :composer
  has_many :video_clips
end
