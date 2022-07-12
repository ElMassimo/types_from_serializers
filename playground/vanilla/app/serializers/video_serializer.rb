class VideoSerializer < BaseSerializer
  object_as :video_clip

  attributes(
    :id,
    :created_at,
    :title,
    :youtube_id,
  )

  type :string, optional: true
  def youtube_url
    video.youtube_url
  end
end
