require "bunny"
require "json"

require "velveteen/commands/rate_limit"
require "velveteen/commands/work"

module Velveteen
  class CLI
    def initialize(argv:, stdout: $stdout)
      @argv = argv
      @command = argv.shift
      @stdout = stdout
    end

    def call
      if Config.connection.nil?
        Config.connection = Bunny.new.start
        Config.queue_class = Bunny::Queue
      end

      stdout.sync = true
      if command == "work"
        Commands::Work.call(argv: argv, stdout: stdout)
      elsif command == "rate-limit"
        Commands::RateLimit.call(argv: argv, stdout: stdout)
      else
        warn "unrecognized command #{command}"
      end
    rescue Interrupt => _
      Config.connection.close
    end

    private

    attr_reader :argv, :command, :stdout
  end
end
