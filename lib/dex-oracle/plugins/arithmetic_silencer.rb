require_relative '../logging'
require_relative '../utility'

class ArithmeticSilencer < Plugin
  include Logging
  include CommonRegex

  def initialize(driver, smali_files, methods)
    @driver = driver
    @smali_files = smali_files
    @methods = methods
    @optimizations = Hash.new(0)
  end

  def process
  end

  def optimizations
    @optimizations
  end

end
