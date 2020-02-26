require "bundler/setup"
require "bunny-mock"
require "pry"

require "velveteen"

Velveteen.logger = Logger.new(IO::NULL)
Velveteen::Config.connection = BunnyMock.new
Velveteen::Config.exchange_name = "velveteen-test-exchange"
Velveteen::Config.queue_class = BunnyMock::Queue
Velveteen::Config.schema_directory = "spec/schemas"

BunnyMock.use_bunny_queue_pop_api = true

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
