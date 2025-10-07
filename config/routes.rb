Rails.application.routes.draw do
  namespace :api do
    post 'auth/register', to: 'auth#register'
    post 'auth/login', to: 'auth#login'
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
