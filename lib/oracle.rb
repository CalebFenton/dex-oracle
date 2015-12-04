require_relative 'dex-oracle/logging'
require_relative 'dex-oracle/plugin'
require_relative 'dex-oracle/smali_file'

class Oracle
  include Logging

  def initialize(smali_dir, driver, include_types, exclude_types)
    Dir["#{File.dirname(__FILE__)}/dex-oracle/plugins/*.rb"].each { |f| require f }
    Plugin.init_plugins(include_types, exclude_types)
    @smali_files = Oracle.parse_smali(smali_dir)
    @driver = driver
    @methods = Oracle.filter_methods(@smali_files, include_types, exclude_types)
  end

  def divine
    made_changes = false
    loop do
      sweep_changes = false
      Plugin.plugins.each do |p|
        sweep_changes |= p.process(@driver, @smali_files, @methods)
      end
      made_changes |= sweep_changes
      break unless sweep_changes
    end

    @smali_files.each { |sf| sf.update } if made_changes
  end

  private

  def self.filter_methods(smali_files, include_types, exclude_types)
    methods = []
    smali_files.each do |smali_file|
      smali_file.methods.each do |method|
        if include_types
          next if !!!(method.descriptor =~ include_types)
        elsif exclude_types && !!(method.descriptor =~ exclude_types)
          next
        end

        methods << method
      end
    end

    methods
  end

  def self.parse_smali(smali_dir)
    smali_files = []
    Dir["#{smali_dir}/**/*.smali"].each { |f| smali_files << SmaliFile.new(f) }
    smali_files
  end
end
