module Users
  class Register
    Result = Data.define(:success?, :user, :errors)

    def self.call(email:, password:, password_confirmation:)
      new(email:, password:, password_confirmation:).call
    end

    def initialize(email:, password:, password_confirmation:)
      @email = email
      @password = password
      @password_confirmation = password_confirmation
    end

    def call
      user = User.new(email: @email, password: @password, password_confirmation: @password_confirmation)

      if user.save
        Result.new(success?: true, user:, errors: nil)
      else
        Result.new(success?: false, user:, errors: user.errors)
      end
    end
  end
end
