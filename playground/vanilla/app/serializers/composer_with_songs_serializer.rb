class ComposerWithSongsSerializer < ComposerSerializer
  class SongSerializer < BaseSerializer
    attributes(:id, :title)
  end

  has_many :songs, serializer: SongSerializer
end
