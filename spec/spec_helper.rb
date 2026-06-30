require "simplecov"

MINIMUM_GROUP_COVERAGE = {
  "Models" => 80.0,
  "Services" => 80.0,
  "Controllers" => 80.0
}.freeze

SimpleCov.start "rails" do
  add_filter "/spec/"
  add_filter "/test/"

  add_group "Models", "app/models"
  add_group "Services", "app/services"
  add_group "Controllers", "app/controllers"
end

SimpleCov.at_exit do
  result = SimpleCov.result
  failures = MINIMUM_GROUP_COVERAGE.filter_map do |group_name, minimum|
    group = result.groups[group_name]
    next unless group
    next if group.covered_percent >= minimum

    format("%s: %.2f%% (minimum %.0f%%)", group_name, group.covered_percent, minimum)
  end

  unless failures.empty?
    warn "\nCoverage thresholds not met:\n#{failures.join("\n")}\n"
    exit 2
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
