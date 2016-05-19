require_relative 'logging'

class Resources
  include Logging

  PATH = File.join(File.dirname(File.expand_path(__FILE__)), '../../res')

  def self.dx
    "#{PATH}/dx.jar"
  end

  def self.driver_dex
    "#{PATH}/driver.dex"
  end
end
