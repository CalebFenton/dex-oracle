class Plugin
  module CommonRegex
    CONST_NUMBER = 'const(?:\/\d+) [vp]\d+, (-?0x[a-f\d]+)'.freeze
    ESCAPE_STRING = '"(.*?)(?<!\\\\)"'.freeze
    CONST_STRING = 'const-string(?:/jumbo)? [vp]\d+, ' << ESCAPE_STRING << '.*'.freeze
    MOVE_RESULT_OBJECT = 'move-result-object ([vp]\d+)'.freeze
  end

  @plugins = []

  def self.plugins
    @plugins
  end

  def self.plugin_classes
    Dir["#{File.dirname(__FILE__)}/plugins/*.rb"].each { |f| require f }
    classes = []
    Object.constants.each do |klass|
      const = Kernel.const_get(klass) unless klass == :TimeoutError
      next unless const.respond_to?(:superclass) && const.superclass == Plugin
      classes << const
    end

    classes
  end

  def self.init_plugins(driver, smali_files, methods)
    @plugins = plugin_classes.collect { |p| p.new(driver, smali_files, methods) }
  end

  def process
    raise 'process not implemented'
  end

  def optimizations
    raise 'optimizations not implemented'
  end

  # method_to_target_to_context -> { method: [target_to_context] }
  # target_to_context -> [ [target, context] ]
  # target = Driver.make_target, has :id key
  # context = [ [original, out_reg] ]
  def self.apply_batch(driver, method_to_target_to_contexts, modifier)
    all_batches = method_to_target_to_contexts.values.collect(&:keys).flatten
    return false if all_batches.empty?

    target_id_to_output = driver.run_batch(all_batches)
    apply_outputs(target_id_to_output, method_to_target_to_contexts, modifier)
  end

  # target_id_to_output -> { id: [status, output] }
  # status = (success|failure)
  def self.apply_outputs(target_id_to_output, method_to_target_to_contexts, modifier)
    made_changes = false
    method_to_target_to_contexts.each do |method, target_to_contexts|
      target_to_contexts.each do |target, contexts|
        status, output = target_id_to_output[target[:id]]
        unless status == 'success'
          logger.warn("Unsuccessful status: #{status} for #{output}")
          next
        end

        contexts.each do |original, out_reg|
          modification = modifier.call(original, output, out_reg)
          #puts "modification #{original.inspect} = #{modification.inspect}"

          # Go home Ruby. You're drunk.
          # (gsub actually _modifies_ the replacement string)
          #modification.gsub!('\\') { '\\\\' }
          #method.body.gsub!(original) { modification }

          dumb_replace(method.body, original, modification)
        end

        made_changes = true
        method.modified = true
      end
    end

    made_changes
  end

  def self.dumb_replace(string, find, replace)
    string[find] = replace while string.include?(find)
    string
  end
end
