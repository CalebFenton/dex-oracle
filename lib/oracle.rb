require_relative 'dex-oracle/logging'
require_relative 'dex-oracle/plugin'
require_relative 'dex-oracle/smali_file'

class Oracle
  include Logging

  def initialize(smali_dir, driver, include_types, exclude_types, disable_plugins)
    @smali_files = Oracle.parse_smali(smali_dir)
    @methods = Oracle.filter_methods(@smali_files, include_types, exclude_types)
    Plugin.init_plugins(driver, @smali_files, @methods)
    @disable_plugins = disable_plugins
    logger.info("Disabled plugins: #{@disable_plugins * ','}") unless @disable_plugins.empty?
  end

  def divine
    puts "Optimizing #{@methods.size} methods over #{@smali_files.size} Smali files."

    made_changes = false
    loop do
      sweep_changes = false
      Plugin.plugins.each do |p|
        next if @disable_plugins.include?(p.class.name.downcase)
        sweep_changes |= p.process
      end
      made_changes |= sweep_changes
      break unless sweep_changes
    end

    optimizations = {}
    Plugin.plugins.each { |p| optimizations.merge!(p.optimizations) }
    opt_str = optimizations.collect {|k,v| "#{k}=#{v}" } * ', '
    puts "Optimizations: #{opt_str}"

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
