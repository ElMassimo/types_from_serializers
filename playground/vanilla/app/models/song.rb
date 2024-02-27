class Song < ApplicationRecord
  belongs_to :composer
  has_many :video_clips

  enum genre: { disco: "disco", rock: "rock", classical: "classical" }
  enum tempo: %w[slow medium fast]
end
