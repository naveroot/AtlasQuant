module Sessions
  class Authenticate
    Result = Data.define(:success?, :user, :error)

    def self.call(email:, password:)
      new(email:, password:).call
    end

    def initialize(email:, password:)
      @email = email
      @password = password
    end

    def call
      user = User.find_by(email: User.normalize_value_for(:email, @email))

      if user&.authenticate(@password)
        Result.new(success?: true, user:, error: nil)
      else
        Result.new(success?: false, user: nil, error: "Invalid email or password")
      end
    end
  end
end
