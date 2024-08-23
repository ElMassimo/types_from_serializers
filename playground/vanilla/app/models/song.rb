class Song < ApplicationRecord
  belongs_to :composer
  has_many :video_clips

  enum genre: {fingerstyle: "fingerstyle", rock: "rock", classical: "classical"}
  enum tempo: %w[slow medium fast]
end
