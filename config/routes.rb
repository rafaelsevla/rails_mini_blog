Rails.application.routes.draw do
  namespace :api do
    post 'auth/register', to: 'auth#register'
    post 'auth/login', to: 'auth#login'
    resources :posts, only: [:index, :show, :create, :update, :destroy] do
      get :my_posts, on: :collection
    end
    get 'posts/users/:username', to: 'posts#posts_by_username'
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
