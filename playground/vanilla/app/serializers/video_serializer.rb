class VideoSerializer < BaseSerializer
  object_as :video_clip

  attributes(
    :id,
    :title,
    :youtube_id,
  )

  typed_attributes(
    youtube_url: :string,
  )
end
