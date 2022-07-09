class VideoClipWithSongSerializer < VideoClipSerializer
  has_one :song, serializer: SongSerializer
end
