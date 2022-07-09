class SongSerializer < BaseSerializer
  attributes(
    :id,
    :title,
  )

  has_one :composer, serializer: ComposerSerializer
end
