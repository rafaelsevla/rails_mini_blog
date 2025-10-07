FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user_#{n}@example.com" }
    name { Faker::Name.name }
    password { "password123" }
    password_confirmation { "password123" }
    
    trait :deleted do
      deleted_at { Time.current }
    end
    
    trait :invalid_password do
      password { "123" }
      password_confirmation { "123" }
    end
  end
end