class SongWithVideosSerializer < SongSerializer
  has_many :video_clips, root: :videos, serializer: VideoClipSerializer
end
