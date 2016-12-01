Rails.application.routes.draw do

  root 'conversations#index'

  resources :conversations, only: [:index, :create] do
    resources :messages, only: [:index, :create]
  end

  get '/register', to: 'users#new'
  post '/register', to: 'users#create'
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
end
