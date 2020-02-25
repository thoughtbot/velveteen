require "logger"

require "velveteen/config"

module Velveteen
  class << self
    attr_accessor :logger
  end

  self.logger = Logger.new($stdout)
end
