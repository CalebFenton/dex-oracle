require 'logger'

module Logging
  class << self
    def logger
      unless @logger
        @logger = Logger.new($stdout)
        @logger.level = Logger::WARN
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "[#{severity}] #{datetime.strftime('%Y-%m-%d %H:%M:%S')}: #{msg}\n"
        end
      end
      @logger
    end

    def logger=(logger)
      @logger = logger
    end
  end

  def self.included(base)
    class << base
      def logger
        Logging.logger
      end
    end
  end

  def logger
    Logging.logger
  end
end
