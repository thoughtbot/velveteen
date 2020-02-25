require "velveteen/run_worker"

module Velveteen
  module Commands
    class Work
      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(argv:, stdout:)
        if argv.length < 2
          warn "expected: velveteen work path/to/worker.rb WorkerClassName"
          exit 1
        end
        @worker_file = argv.shift
        @worker_class_name = argv.shift
        @stdout = stdout
      end

      def call
        stdout.puts " [*] Waiting for messages. To exit press CTRL+C"

        require File.expand_path(worker_file)
        worker_class = Object.const_get(worker_class_name)

        RunWorker.new(worker_class: worker_class).call
      end

      private

      attr_reader :stdout, :worker_file, :worker_class_name
    end
  end
end
