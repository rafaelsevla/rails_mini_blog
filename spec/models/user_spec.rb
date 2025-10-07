require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }
    
    context 'when all fields are valid' do
      it 'is valid' do
        expect(subject).to be_valid
      end
    end
    
    context 'name validation' do
      it 'is required' do
        subject.name = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:name]).to include("can't be blank")
      end
      
      it 'cannot be empty' do
        subject.name = ''
        expect(subject).not_to be_valid
      end
    end
    
    context 'email validation' do
      it 'is required' do
        subject.email = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to include("can't be blank")
      end
      
      it 'must have valid format' do
        invalid_emails = ['invalid', '@example.com', 'user@', 'user example.com']
        
        invalid_emails.each do |invalid_email|
          subject.email = invalid_email
          expect(subject).not_to be_valid, "#{invalid_email} should be invalid"
        end
      end
      
      it 'accepts valid emails' do
        valid_emails = ['user@example.com', 'user.name@example.co.uk', 'user+tag@example.com']
        
        valid_emails.each do |valid_email|
          subject.email = valid_email
          expect(subject).to be_valid, "#{valid_email} should be valid"
        end
      end
      
      it 'must be unique' do
        create(:user, email: 'duplicate@example.com')
        
        duplicate_user = build(:user, email: 'duplicate@example.com')
        expect(duplicate_user).not_to be_valid
        expect(duplicate_user.errors[:email]).to include("has already been taken")
      end
      
      it 'allows duplicate email if first was deleted (soft delete)' do
        deleted_user = create(:user, email: 'reusable@example.com')
        deleted_user.destroy
        
        new_user = build(:user, email: 'reusable@example.com')
        expect(new_user).to be_valid
      end
    end
    
    context 'password validation' do
      it 'is required when creating new user' do
        user = build(:user, password: nil, password_confirmation: nil)
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("can't be blank")
      end
      
      it 'must have at least 6 characters' do
        subject.password = '123'
        subject.password_confirmation = '123'
        expect(subject).not_to be_valid
        expect(subject.errors[:password]).to include("is too short (minimum is 6 characters)")
      end
      
      it 'must match password_confirmation' do
        subject.password = 'password123'
        subject.password_confirmation = 'password456'
        expect(subject).not_to be_valid
        expect(subject.errors[:password_confirmation]).to include("doesn't match Password")
      end
      
      it 'does not validate password when updating other fields' do
        user = create(:user, password: 'password123')
        
        user.name = 'New Name'
        expect(user).to be_valid
        expect(user.save).to be true
      end
    end
  end
  
  describe 'has_secure_password' do
    let(:user) { create(:user, password: 'password123') }
    
    it 'encrypts password in password_digest' do
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq('password123')
    end
    
    it 'authenticates with correct password' do
      expect(user.authenticate('password123')).to eq(user)
    end
    
    it 'does not authenticate with incorrect password' do
      expect(user.authenticate('wrong_password')).to be false
    end
  end
  
  describe 'soft delete (paranoia)' do
    let(:user) { create(:user) }
    
    it 'sets deleted_at when deleted' do
      expect(user.deleted_at).to be_nil
      
      user.destroy
      
      expect(user.deleted_at).to be_present
      expect(user.deleted?).to be true
    end
    
    it 'does not appear in default queries after deletion' do
      user
      
      expect(User.count).to eq(1)
      
      user.destroy
      
      expect(User.count).to eq(0)
      expect(User.with_deleted.count).to eq(1)
    end
    
    it 'can be restored' do
      user.destroy
      expect(User.count).to eq(0)
      
      user.restore
      
      expect(User.count).to eq(1)
      expect(user.deleted_at).to be_nil
    end
    
    it 'can be permanently deleted' do
      user.really_destroy!
      
      expect(User.with_deleted.count).to eq(0)
    end
  end
end