require 'set'

class Plugin
  module CommonRegex
    CONST_NUMBER = 'const(?:\/\d+) [vp]\d+, (-?0x[a-f\d]+)'
    ESCAPE_STRING = '"(.*?)(?<!\\\\)"'
    CONST_STRING = 'const-string [vp]\d+, ' << ESCAPE_STRING << '.*'
    MOVE_RESULT_OBJECT = 'move-result-object ([vp]\d+)'
  end

  @plugins = Set.new

  def self.plugins
    @plugins
  end

  def self.init_plugins(include_types, exclude_types)
    Object.constants.each do |klass|
      const = Kernel.const_get(klass)
      next unless const.respond_to?(:superclass) && const.superclass == Plugin
      @plugins << const
    end
  end

  def self.apply_batch(driver, method_to_batch_info, modifier)
    all_batches = method_to_batch_info.values.collect { |e| e.keys }.flatten
    return false if all_batches.empty?

    outputs = driver.run_batch(all_batches)

    made_changes = false
    method_to_batch_info.each do |method, batch_info|
      batch_info.each do |item, infos|
        status, output = outputs[item[:id]]
        unless status == 'success'
          logger.warn(output)
          next
        end

        infos.each do |original, out_reg|
          modification = modifier.call(original, output, out_reg)
          #puts "modification #{original.inspect} = #{modification.inspect}"

          # Go home Ruby, you're drunk.
          modification.gsub!('\\') { '\\\\' }
          method.body.gsub!(original) { modification }
        end

        made_changes = true
        method.modified = true
      end
    end

    made_changes
  end
end
