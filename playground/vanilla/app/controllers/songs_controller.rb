class SongsController < ApplicationController
  def index
    render_page songs: SongSerializer.many(Song.all.order(:title))
  end

  def show
    render_page song: SongWithVideosSerializer.one(Song.find(params[:id]))
  end
end
