class VideosController < ApplicationController
  def index
    render_page videos: VideoWithSongSerializer.many(VideoClip.all.order(:created_at))
  end

  def show
    render_page video: VideoWithSongSerializer.one(VideoClip.find(params[:id]))
  end
end
