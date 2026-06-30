module StubHelpers
  def with_stubbed_class_method(klass, method_name, implementation)
    original = klass.method(method_name)
    klass.define_singleton_method(method_name, &implementation)
    yield
  ensure
    klass.define_singleton_method(method_name, original)
  end

  def with_stubbed_instance_method(object, method_name, implementation)
    original = object.method(method_name)
    object.define_singleton_method(method_name, &implementation)
    yield
  ensure
    object.define_singleton_method(method_name, original)
  end

  def with_memory_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache.lookup_store(:memory_store)

    yield
  ensure
    Rails.cache = original_cache
  end
end

RSpec.configure do |config|
  config.include StubHelpers
end
