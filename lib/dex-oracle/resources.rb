class Resources
  include Logging

  PATH = File.join(File.dirname(File.expand_path(__FILE__)), '../../res')

  def self.dx
    return "#{PATH}/dx.jar"
  end

  def self.driver_dex
    return "#{PATH}/driver.dex"
  end
end
