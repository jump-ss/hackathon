Rails.application.routes.draw do
  get 'game/index'
  post 'game/process_command'
  root 'game#index'

  match 'messages', to: 'messages#create', via: %i[options post]
  resources :messages, only: [:create]
end
