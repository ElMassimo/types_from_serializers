class Nested::AlbumSerializer < BaseSerializer
  flat_one :album, serializer: ModelSerializer

  has_many :songs, as: :tracks, serializer: SongSerializer
end
