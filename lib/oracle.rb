require_relative 'plugin'

class Oracle
  def initialize(smali_dir)
    Dir['./plugins/*.rb'].each { |f| require f }
    Plugin.register_plugins
    @smali_files = parse_smali(smali_dir)
  end

  def divine
    @smali_files.each do |smali_file|
      Plugin.plugins.each { |p| p.process(smali_file) }
    end
  end

  private

  def parse_smali(smali_dir)

  end
end
