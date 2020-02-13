require "spec_helper"

require "velveteen/cli"

RSpec.describe Velveteen::CLI do
  it "supports a work command" do
    argv = %w[
      work
      path/to/nonexistent_worker.rb
      NonexistentWorker
    ]
    out = StringIO.new
    allow(Velveteen::Commands::Work).to receive(:call)
    cli = described_class.new(argv: argv, stdout: out)

    cli.call

    forwarded_argv = %w[
      path/to/nonexistent_worker.rb
      NonexistentWorker
    ]
    expect(Velveteen::Commands::Work).to have_received(:call)
      .with(argv: forwarded_argv, stdout: out)
  end
end
