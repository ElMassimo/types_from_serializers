Rails.application.routes.draw do
  root to: "videos#index"

  defaults export: true do
    resources :composers, only: %i[index show], export: true
    resources :songs, only: %i[index show], export: true
    resources :videos, only: %i[index show], export: true
  end
end
