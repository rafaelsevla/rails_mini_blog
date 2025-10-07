# spec/requests/api/auth_spec.rb

require 'rails_helper'

RSpec.describe 'Api::Auth', type: :request do
  describe 'POST /api/auth/register' do
    let(:url) { '/api/auth/register' }
    
    context 'with valid parameters' do
      let(:valid_params) do
        {
          name: 'John Doe',
          email: 'john@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      end
      
      it 'creates a new user' do
        expect {
          post url, params: valid_params, as: :json
        }.to change(User, :count).by(1)
      end
      
      it 'returns status 201 (created)' do
        post url, params: valid_params, as: :json
        
        expect(response).to have_http_status(:created)
      end
      
      it 'returns created user data' do
        post url, params: valid_params, as: :json
        
        json = JSON.parse(response.body)
        
        expect(json['message']).to eq('Usuário criado com sucesso')
        expect(json['user']).to include(
          'id' => be_present,
          'name' => 'John Doe',
          'email' => 'john@example.com',
          'created_at' => be_present,
          'updated_at' => be_present
        )
      end
      
      it 'returns a JWT token' do
        post url, params: valid_params, as: :json
        
        json = JSON.parse(response.body)
        
        expect(json['token']).to be_present
        
        decoded = JWT.decode(
          json['token'],
          Rails.application.secret_key_base,
          true,
          { algorithm: 'HS256' }
        )[0]
        
        expect(decoded['user_id']).to eq(User.last.id)
        expect(decoded['exp']).to be_present
        expect(decoded['iat']).to be_present
      end
      
      it 'does not return password_digest in response' do
        post url, params: valid_params, as: :json
        
        json = JSON.parse(response.body)
        
        expect(json['user']).not_to have_key('password_digest')
        expect(json['user']).not_to have_key('password')
      end
      
      it 'encrypts the password' do
        post url, params: valid_params, as: :json
        
        user = User.last
        expect(user.password_digest).to be_present
        expect(user.password_digest).not_to eq('password123')
        expect(user.authenticate('password123')).to eq(user)
      end
    end
    
    context 'with invalid parameters' do
      context 'when email is blank' do
        let(:invalid_params) do
          {
            name: 'John Doe',
            email: '',
            password: 'password123',
            password_confirmation: 'password123'
          }
        end
        
        it 'does not create the user' do
          expect {
            post url, params: invalid_params, as: :json
          }.not_to change(User, :count)
        end
        
        it 'returns status 422 (unprocessable entity)' do
          post url, params: invalid_params, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
        end
        
        it 'returns error messages' do
          post url, params: invalid_params, as: :json
          
          json = JSON.parse(response.body)
          
          expect(json['errors']).to be_an(Array)
          expect(json['errors']).to include(match(/can't be blank/))
        end
      end
      
      context 'when email has invalid format' do
        it 'returns validation error' do
          post url, params: {
            name: 'John Doe',
            email: 'invalid_email',
            password: 'password123',
            password_confirmation: 'password123'
          }, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          
          json = JSON.parse(response.body)
          expect(json['errors']).to include(match(/is invalid/))
        end
      end
      
      context 'when email already exists' do
        before do
          create(:user, email: 'duplicate@example.com')
        end
        
        it 'returns validation error' do
          post url, params: {
            name: 'Another Name',
            email: 'duplicate@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          
          json = JSON.parse(response.body)
          expect(json['errors']).to include(match(/has already been taken/))
        end
      end
      
      context 'when name is blank' do
        it 'returns validation error' do
          post url, params: {
            name: '',
            email: 'john@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          
          json = JSON.parse(response.body)
          expect(json['errors']).to include(match(/can't be blank/))
        end
      end
      
      context 'when password is too short' do
        it 'returns validation error' do
          post url, params: {
            name: 'John Doe',
            email: 'john@example.com',
            password: '123',
            password_confirmation: '123'
          }, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          
          json = JSON.parse(response.body)
          expect(json['errors']).to include(match(/is too short/))
        end
      end
      
      context 'when passwords do not match' do
        it 'returns validation error' do
          post url, params: {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'password123',
            password_confirmation: 'password456'
          }, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          
          json = JSON.parse(response.body)
          expect(json['errors']).to include(match(/doesn't match/))
        end
      end
      
      context 'when required fields are missing' do
        it 'returns multiple errors' do
          post url, params: {
            name: '',
            email: '',
            password: '',
            password_confirmation: ''
          }, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          
          json = JSON.parse(response.body)
          expect(json['errors'].length).to be >= 3
        end
      end
    end
    
    context 'strong parameters (mass assignment protection)' do
      it 'ignores unpermitted fields' do
        post url, params: {
          name: 'Hacker',
          email: 'hacker@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          admin: true,
          role: 'superuser'
        }, as: :json
        
        expect(response).to have_http_status(:created)
        
        user = User.last
        expect(user).not_to respond_to(:admin)
        expect(user).not_to respond_to(:role)
      end
    end
    
    context 'allows duplicate email if first was deleted' do
      it 'creates new user with email from deleted user' do
        deleted_user = create(:user, email: 'reusable@example.com')
        deleted_user.destroy
        
        post url, params: {
          name: 'New User',
          email: 'reusable@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }, as: :json
        
        expect(response).to have_http_status(:created)
        expect(User.count).to eq(1)
        expect(User.with_deleted.count).to eq(2)
      end
    end
  end

  describe 'POST /api/auth/login' do
    let(:url) { '/api/auth/login' }
    let!(:user) { create(:user, email: 'john@example.com', password: 'password123', password_confirmation: 'password123') }
    
    context 'with valid credentials' do
      let(:valid_credentials) do
        {
          email: 'john@example.com',
          password: 'password123'
        }
      end
      
      it 'returns status 200 (ok)' do
        post url, params: valid_credentials, as: :json
        
        expect(response).to have_http_status(:ok)
      end
      
      it 'returns success message' do
        post url, params: valid_credentials, as: :json
        
        json = JSON.parse(response.body)
        
        expect(json['message']).to eq('Login realizado com sucesso')
      end
      
      it 'returns user data' do
        post url, params: valid_credentials, as: :json
        
        json = JSON.parse(response.body)
        
        expect(json['user']).to include(
          'id' => user.id,
          'name' => user.name,
          'email' => user.email,
          'created_at' => be_present,
          'updated_at' => be_present
        )
      end
      
      it 'returns a JWT token' do
        post url, params: valid_credentials, as: :json
        
        json = JSON.parse(response.body)
        
        expect(json['token']).to be_present
        
        decoded = JWT.decode(
          json['token'],
          Rails.application.secret_key_base,
          true,
          { algorithm: 'HS256' }
        )[0]
        
        expect(decoded['user_id']).to eq(user.id)
        expect(decoded['exp']).to be_present
        expect(decoded['iat']).to be_present
      end
      
      it 'does not return password_digest' do
        post url, params: valid_credentials, as: :json
        
        json = JSON.parse(response.body)
        
        expect(json['user']).not_to have_key('password_digest')
        expect(json['user']).not_to have_key('password')
      end
    end
    
    context 'with invalid credentials' do
      context 'when password is incorrect' do
        let(:invalid_credentials) do
          {
            email: 'john@example.com',
            password: 'wrong_password'
          }
        end
        
        it 'returns status 401 (unauthorized)' do
          post url, params: invalid_credentials, as: :json
          
          expect(response).to have_http_status(:unauthorized)
        end
        
        it 'returns generic error message' do
          post url, params: invalid_credentials, as: :json
          
          json = JSON.parse(response.body)
          
          expect(json['error']).to eq('Invalid email or password')
        end
        
        it 'does not return token' do
          post url, params: invalid_credentials, as: :json
          
          json = JSON.parse(response.body)
          
          expect(json).not_to have_key('token')
        end
      end
      
      context 'when email does not exist' do
        let(:invalid_credentials) do
          {
            email: 'notfound@example.com',
            password: 'password123'
          }
        end
        
        it 'returns status 401 (unauthorized)' do
          post url, params: invalid_credentials, as: :json
          
          expect(response).to have_http_status(:unauthorized)
        end
        
        it 'returns generic error message' do
          post url, params: invalid_credentials, as: :json
          
          json = JSON.parse(response.body)
          
          expect(json['error']).to eq('Invalid email or password')
        end
      end
      
      context 'when email is blank' do
        it 'returns unauthorized' do
          post url, params: {
            email: '',
            password: 'password123'
          }, as: :json
          
          expect(response).to have_http_status(:unauthorized)
        end
      end
      
      context 'when password is blank' do
        it 'returns unauthorized' do
          post url, params: {
            email: 'john@example.com',
            password: ''
          }, as: :json
          
          expect(response).to have_http_status(:unauthorized)
        end
      end
      
      context 'when both fields are blank' do
        it 'returns unauthorized' do
          post url, params: {
            email: '',
            password: ''
          }, as: :json
          
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
    
    context 'when user is soft deleted' do
      it 'does not allow login' do
        user.destroy  # soft delete
        
        post url, params: {
          email: 'john@example.com',
          password: 'password123'
        }, as: :json
        
        expect(response).to have_http_status(:unauthorized)
        
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid email or password')
      end
    end
    
    context 'case sensitivity' do
      it 'is case sensitive for email' do
        post url, params: {
          email: 'JOHN@EXAMPLE.COM',  # uppercase
          password: 'password123'
        }, as: :json
        
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'is case sensitive for password' do
        post url, params: {
          email: 'john@example.com',
          password: 'PASSWORD123'  # uppercase
        }, as: :json
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end