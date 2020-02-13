require "bunny"
require "json"

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
      if command == "work"
        Commands::Work.new(argv: argv, stdout: stdout).call
      end
    end

    private

    attr_reader :argv, :command, :stdout
  end
end
