Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]

  resources :instruments, only: %i[index show], param: :secid

  root "home#index"
end
