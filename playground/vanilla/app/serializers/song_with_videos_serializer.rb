class SongWithVideosSerializer < SongSerializer
  has_many :video_clips, as: :videos, serializer: VideoSerializer
end
