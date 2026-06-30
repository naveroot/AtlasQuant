Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]

  resources :instruments, only: %i[index show], param: :secid do
    resource :favorite, only: %i[create destroy], controller: "favorite_instruments"
  end

  resources :favorites, only: %i[index], controller: "favorite_instruments"
  resource :feedback, only: %i[new create]

  root "home#index"
end
