class Ams::SongSerializer < Ams::BaseSerializer
  object_as :song

  attributes(
    :id,
    :title,
  )

  has_one :composer, serializer: Ams::ComposerSerializer
end
