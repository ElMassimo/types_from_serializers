class SongSerializer < BaseSerializer
  attributes(
    :id,
    :title,
    :genre,
    :tempo,
    :explicit_lyrics,
    :vocal_track,
  )

  has_one :composer, serializer: ComposerSerializer
end
