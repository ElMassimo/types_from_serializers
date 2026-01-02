class Song < ApplicationRecord
  belongs_to :composer
  has_many :video_clips

  if Rails::VERSION::MAJOR >= 7
    enum :genre, fingerstyle: "fingerstyle", rock: "rock", classical: "classical"
    enum :tempo, %w[slow medium fast]
  else
    enum genre: {fingerstyle: "fingerstyle", rock: "rock", classical: "classical"}
    enum tempo: %w[slow medium fast]
  end
end
