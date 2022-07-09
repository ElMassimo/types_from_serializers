class VideosController < ApplicationController
  def index
    render_page videos: VideoClipWithSongSerializer.many(VideoClip.all.order(:created_at))
  end

  def show
    render_page video: VideoClipWithSongSerializer.one(VideoClip.find(params[:id]))
  end
end
