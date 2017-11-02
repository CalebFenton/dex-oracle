require_relative '../logging'
require_relative '../utility'

class IndexedStringLookup < Plugin
  attr_reader :optimizations

  include Logging
  include CommonRegex

  STRING_DECRYPT = Regexp.new(
    '^[ \t]*(' +
    (CONST_NUMBER_CAPTURE + '\s+') +
    'invoke-static \{\2\}, L([^;]+);->([^\(]+\(I\))Ljava/lang/String;' \
    '\s+' +
    MOVE_RESULT_OBJECT + ')'
  )

  MODIFIER = -> (_, output, out_reg) { "const-string #{out_reg}, \"#{output.split('').collect { |e| e.inspect[1..-2] }.join}\"" }

  def initialize(driver, smali_files, methods)
    @driver = driver
    @smali_files = smali_files
    @methods = methods
    @optimizations = Hash.new(0)
  end

  def process
    method_to_target_to_contexts = {}
    @methods.each do |method|
      logger.info("Decrypting indexed strings #{method.descriptor}")
      target_to_contexts = {}
      target_to_contexts.merge!(decrypt_strings(method))
      target_to_contexts.map { |_, v| v.uniq! }
      method_to_target_to_contexts[method] = target_to_contexts unless target_to_contexts.empty?
    end

    made_changes = false
    made_changes |= Plugin.apply_batch(@driver, method_to_target_to_contexts, MODIFIER)

    made_changes
  end

  private

  def decrypt_strings(method)
    target_to_contexts = {}
    matches = method.body.scan(STRING_DECRYPT)
    @optimizations[:string_lookups] += matches.size if matches
    matches.each do |original, _, str_index, class_name, method_signature, out_reg|
      target = @driver.make_target(
        class_name, method_signature, str_index.to_i(16)
      )
      target_to_contexts[target] = [] unless target_to_contexts.key?(target)
      target_to_contexts[target] << [original, out_reg]
    end

    target_to_contexts
  end
end
