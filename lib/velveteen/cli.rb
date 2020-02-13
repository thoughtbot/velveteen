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
      stdout.sync = true
      config = Config.new(connection: Bunny.new.start)

      if command == "work"
        Commands::Work.call(argv: argv, stdout: stdout)
      elsif command == "rate-limit"
        Commands::RateLimit.call(argv: argv, stdout: stdout, config: config)
      else
        warn "unrecognized command #{command}"
      end
    rescue Interrupt => _
      config.connection.close
    end

    private

    attr_reader :argv, :command, :stdout
  end

  Config = Struct.new(:connection, keyword_init: true)
end
