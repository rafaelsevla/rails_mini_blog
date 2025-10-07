Rails.application.routes.draw do
  namespace :api do
    # Rotas de autenticação
    post 'auth/register', to: 'auth#register'
    # post 'auth/login', to: 'auth#login'  # vamos fazer depois
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
