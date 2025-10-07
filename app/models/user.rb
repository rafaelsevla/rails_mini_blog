class User < ApplicationRecord
  acts_as_paranoid
  has_secure_password

  has_many :posts, dependent: :destroy
  
  validates :email, 
            presence: true,
            uniqueness: { conditions: -> { where(deleted_at: nil) } }, # ignora deletados
            format: { with: URI::MailTo::EMAIL_REGEXP }
  
  validates :name, presence: true
  validates :password, 
            length: { minimum: 6 }, 
            if: :password_digest_changed?
  validates :username, presence: true, uniqueness: true

  before_validation :generate_username, on: :create

  private

  def generate_username
    base = email.split('@').first.downcase.gsub(/[^a-z0-9_]/, '_')
    candidate = base
    counter = 1

    # Evita conflito com usernames existentes
    while User.exists?(username: candidate)
      candidate = "#{base}_#{counter}"
      counter += 1
    end

    self.username = candidate
  end
end