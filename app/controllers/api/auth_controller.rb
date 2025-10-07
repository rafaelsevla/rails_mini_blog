class Api::AuthController < ApplicationController
  def register
    user = User.new(user_params)
    if user.save
      token = encode_token(user_id: user.id, exp: 24.hours.from_now.to_i)
      render json: {
        message: 'Usuário criado com sucesso',
        user: user_response(user),
        token: token
      }, status: :created
    else
      render json: { 
        errors: user.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: login_params[:email])
    if user&.authenticate(login_params[:password])
      token = encode_token(user_id: user.id, exp: 24.hours.from_now.to_i)
      render json: {
        message: 'Login realizado com sucesso',
        user: user_response(user),
        token: token
      }, status: :ok
    else
      render json: {
        error: 'Invalid email or password'
      }, status: :unauthorized
    end
  end

  private

  def user_params
    params.permit(:name, :email, :password, :password_confirmation)
  end
  
  def login_params
    params.permit(:email, :password)
  end
  
  def user_response(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      username: user.username,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end