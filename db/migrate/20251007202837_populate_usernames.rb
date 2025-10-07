class PopulateUsernames < ActiveRecord::Migration[7.1]
  def up
    User.reset_column_information

    User.find_each do |user|
      next if user.username.present?

      base = user.email.split('@').first.downcase.gsub(/[^a-z0-9_]/, '_')
      candidate = base
      counter = 1

      while User.exists?(username: candidate)
        candidate = "#{base}_#{counter}"
        counter += 1
      end

      user.update_column(:username, candidate)
    end
  end

  def down
    # opcional: remover usernames se quiser reverter
    User.update_all(username: nil)
  end
end
