class SongWithVideosSerializer < SongSerializer
  has_many :video_clips, root: :videos, serializer: VideoSerializer
end
