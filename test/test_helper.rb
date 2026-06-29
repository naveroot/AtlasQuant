ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    def with_stubbed_class_method(klass, method_name, implementation)
      original = klass.method(method_name)
      klass.define_singleton_method(method_name, &implementation)
      yield
    ensure
      klass.define_singleton_method(method_name, original)
    end
  end
end
