require_relative 'dex-oracle/logging'
require_relative 'dex-oracle/plugin'
require_relative 'dex-oracle/smali_file'

class Oracle
  include Logging

  def initialize(smali_dir, driver)
    Dir["#{File.dirname(__FILE__)}/dex-oracle/plugins/*.rb"].each { |f| require f }
    Plugin.register_plugins
    @smali_files = Oracle.parse_smali(smali_dir)
    @driver = driver
  end

  def divine
    made_changes = false
    loop do
      sweep_changes = false
      Plugin.plugins.each { |p| sweep_changes |= p.process(@driver, @smali_files) }
      made_changes |= sweep_changes
      break unless sweep_changes
    end

    @smali_files.each { |sf| sf.update } if made_changes
  end

  private

  def self.parse_smali(smali_dir)
    smali_files = []
    Dir["#{smali_dir}/**/*.smali"].each { |f| smali_files << SmaliFile.new(f) }
    smali_files
  end
end
