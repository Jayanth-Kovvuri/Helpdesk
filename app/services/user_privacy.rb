# frozen_string_literal: true

class UserPrivacy
  class << self
    def destroy_account!(user)
      user.destroy!
    end
  end
end
