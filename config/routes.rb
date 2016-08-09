Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  devise_for :users
  root 'conversations#index'

  resources :conversations, only: [:index, :create] do
    resources :messages, only: [:index, :create]
  end
end
