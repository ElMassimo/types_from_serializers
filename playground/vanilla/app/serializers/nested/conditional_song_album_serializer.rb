class Nested::ConditionalSongAlbumSerializer < BaseSerializer
  flat_one :album, serializer: SongSerializer, if: -> { object.album }

  has_many :songs, as: :tracks, serializer: SongSerializer
end
