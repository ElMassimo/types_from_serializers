class VideoWithSongSerializer < VideoSerializer
  has_one :song, serializer: SongSerializer
end
