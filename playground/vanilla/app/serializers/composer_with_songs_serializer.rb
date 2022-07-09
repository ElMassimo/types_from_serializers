class ComposerWithSongsSerializer < ComposerSerializer
  has_many :songs, serializer: ModelSerializer
end
