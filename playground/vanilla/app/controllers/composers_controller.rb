class ComposersController < ApplicationController
  def index
    render_page composers: ComposerSerializer.many(Composer.all)
  end

  def show
    render_page composer: ComposerWithSongsSerializer.one(Composer.find(params[:id]))
  end
end
