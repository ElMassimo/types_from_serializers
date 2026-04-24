class Nested::SongSummarySerializer < BaseSerializer
  type "Song[]"
  def songs
  end
end
