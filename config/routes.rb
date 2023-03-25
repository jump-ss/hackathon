Rails.application.routes.draw do
  match 'messages', to: 'messages#create', via: %i[options post]
  resources :messages, only: [:create]
end
