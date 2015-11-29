require_relative 'dex-oracle/plugin'
require_relative 'dex-oracle/smali_file'

class Oracle
  def initialize(smali_dir)
    Dir['./plugins/*.rb'].each { |f| require f }
    Plugin.register_plugins
    @smali_files = Oracle.parse_smali(smali_dir)
  end

  def divine
    @smali_files.each do |smali_file|
      Plugin.plugins.each { |p| p.process(smali_file) }
    end
  end

  private

  def self.parse_smali(smali_dir)
    smali_files = []
    Dir["#{smali_dir}/*.smali"].each { |f| smali_files << SmaliFile.new(f) }
    smali_files
  end
end
