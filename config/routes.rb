Rails.application.routes.draw do
  devise_for :users
  root 'conversations#index'

  resources :conversations, only: [:index, :create] do
    resources :messages, only: [:index, :create]
  end
end
