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
    made_changes = process_plugins
    @smali_files.each(&:update) if made_changes
    optimizations = {}
    Plugin.plugins.each { |p| optimizations.merge!(p.optimizations) }
    opt_str = optimizations.collect { |k, v| "#{k}=#{v}" } * ', '
    puts "Optimizations: #{opt_str}"
  end

  def process_plugins
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
    made_changes
  end

  def self.filter_methods(smali_files, include_types, exclude_types)
    methods = []
    smali_files.each do |smali_file|
      smali_file.methods.each do |method|
        if include_types
          next if method.descriptor !~ include_types
        elsif exclude_types && !(method.descriptor !~ exclude_types)
          next
        end
        methods << method
      end
    end

    methods
  end

  def self.enumerate_files(dir, ext)
    # On Windows, filenames with unicode characters do not show up with Dir#glob or Dir#[]
    # They do, however, show up with Dir.entries, which is fine because it seems to be
    # the only Dir method that let's me set UTF-8 encoding. I must be missing something.
    # OH WELL. Do it the hard way.
    opts = { encoding: 'UTF-8' }
    Dir.entries(dir, opts).collect do |entry|
      next if entry == '.' or entry == '..'
      full_path = "#{dir}/#{entry}"
      if File.directory?(full_path)
        Oracle.enumerate_files(full_path, ext)
      else
        full_path if entry.downcase.end_with?(ext)
      end
    end.flatten.compact
  end

  def self.parse_smali(smali_dir)
    file_paths = Oracle.enumerate_files(smali_dir, '.smali')
    smali_files = file_paths.collect { |path| SmaliFile.new(path) }
  end
end
