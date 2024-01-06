class Nested::ConditionalAlbumSerializer < BaseSerializer
  flat_one :album, serializer: ModelSerializer, if: -> { object.album }

  has_many :songs, as: :tracks, serializer: SongSerializer
end
