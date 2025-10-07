class Post < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :user
  
  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :content, presence: true, length: { minimum: 10 }
  validates :user, presence: true
end