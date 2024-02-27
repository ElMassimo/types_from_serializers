class SongSerializer < BaseSerializer
  attributes(
    :id,
    :title,
    :genre,
    :tempo,
  )

  has_one :composer, serializer: ComposerSerializer
end
