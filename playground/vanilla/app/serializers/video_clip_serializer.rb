class VideoClipSerializer < BaseSerializer
  attributes(
    :id,
    :title,
    :youtube_id,
  )

  typed_attributes(
    youtube_url: :string,
  )
end
