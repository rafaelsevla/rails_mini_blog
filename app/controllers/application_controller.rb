class ApplicationController < ActionController::API
  def encode_token(payload)
    payload[:iat] = Time.now.to_i
    
    JWT.encode(
      payload,
      Rails.application.secret_key_base,
      'HS256'
    )
  end

  def decode_token(token)
    decoded = JWT.decode(
      token,
      Rails.application.secret_key_base,
      true,
      { algorithm: 'HS256' }
    )
    decoded[0]
    
  rescue JWT::ExpiredSignature
    nil
  rescue JWT::DecodeError
    nil
  end

  def auth_token
    header = request.headers['Authorization']
    return nil unless header
    header.split(' ').last
  end
  
  def current_user
    return @current_user if defined?(@current_user)  # memoization
    
    token = auth_token
    return nil unless token
    
    decoded = decode_token(token)
    return nil unless decoded
    
    @current_user = User.find_by(id: decoded['user_id'])
  end
  
  def logged_in?
    !!current_user
  end
  
  def authenticate_user!
    unless logged_in?
      render json: { error: 'Não autorizado. Token inválido ou ausente.' }, status: :unauthorized
    end
  end
end