require_relative '../logging'
require_relative '../utility'

class Undexguard < Plugin
  attr_reader :optimizations

  include Logging
  include CommonRegex

  STRING_LOOKUP_3INT = Regexp.new(
    '^[ \t]*(' +
    ((CONST_NUMBER_CAPTURE + '\s+') * 3) +
    'invoke-static \{\2, \4, \6\}, L([^;]+);->([^\(]+\(III\))Ljava/lang/String;' \
    '\s+' +
    MOVE_RESULT_OBJECT + ')',
    Regexp::MULTILINE
  )

  STRING_LOOKUP_1INT = Regexp.new(
    '^[ \t]*(' +
    CONST_NUMBER_CAPTURE + '\s+' \
    'invoke-static \{\2\}, L([^;]+);->([^\(]+\(I\))Ljava/lang/String;' \
    '\s+' +
    MOVE_RESULT_OBJECT + ')'
  )

  BYTES_DECRYPT = Regexp.new(
    '^[ \t]*(' +
    CONST_STRING_CAPTURE + '\s+' \
    'invoke-virtual \{\2\}, Ljava\/lang\/String;->getBytes\(\)\[B\s+' \
    'move-result-object ([vp]\d+)\s+' \
    'invoke-static \{\4\}, L([^;]+);->([^\(]+\(\[B\))Ljava/lang/String;' \
    '\s+' +
    MOVE_RESULT_OBJECT + ')'
  )

  # Probably so specific it doesn't need to use CAPTURE regexes to prevent false positives
  MULTI_BYTES_DECRYPT = Regexp.new(
    '^[ \t]*(' +
    CONST_STRING + '\s+' \
    'new-instance ([vp]\d+), L[^;]+;\s+' \
    'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+\(Ljava/lang/String;\))\[B\s+' \
    'move-result-object [vp]\d+\s+' +
    CONST_STRING + '\s+' \
    'invoke-static \{[vp]\d+, [vp]\d+\}, L([^;]+);->([^\(]+\(\[BLjava/lang/String;\))\[B\s+' \
    'move-result-object [vp]\d+\s+' \
    'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+\(\[B\))\[B\s+' \
    'move-result-object [vp]\d+\s+' \
    'invoke-direct \{[vp]\d+, [vp]\d+\}, Ljava\/lang\/String;-><init>\(\[B\)V' \
    ')'
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
      logger.info("Undexguarding #{method.descriptor} - stage 1/2")
      target_to_contexts = {}
      target_to_contexts.merge!(lookup_strings_3int(method))
      target_to_contexts.merge!(lookup_strings_1int(method))
      target_to_contexts.merge!(decrypt_bytes(method))
      target_to_contexts.map { |_, v| v.uniq! }
      method_to_target_to_contexts[method] = target_to_contexts unless target_to_contexts.empty?
    end

    made_changes = Plugin.apply_batch(@driver, method_to_target_to_contexts, MODIFIER)

    @methods.each do |method|
      logger.info("Undexguarding #{method.descriptor} - stage 2/2")
      made_changes |= decrypt_multi_bytes(method)
    end

    made_changes
  end

  private

  def lookup_strings_3int(method)
    target_to_contexts = {}
    matches = method.body.scan(STRING_LOOKUP_3INT)
    @optimizations[:string_lookups] += matches.size if matches
    matches.each do |original, _, arg1, _, arg2, _, arg3, class_name, method_signature, out_reg|
      target = @driver.make_target(
        class_name, method_signature, arg1.to_i(16), arg2.to_i(16), arg3.to_i(16)
      )
      target_to_contexts[target] = [] unless target_to_contexts.key?(target)
      target_to_contexts[target] << [original, out_reg]
    end

    target_to_contexts
  end

  def lookup_strings_1int(method)
    target_to_contexts = {}
    matches = method.body.scan(STRING_LOOKUP_1INT)
    @optimizations[:string_lookups] += matches.size if matches
    matches.each do |original, _, arg1, class_name, method_signature, out_reg|
      target = @driver.make_target(
        class_name, method_signature, arg1.to_i(16)
      )
      target_to_contexts[target] = [] unless target_to_contexts.key?(target)
      target_to_contexts[target] << [original, out_reg]
    end

    target_to_contexts
  end

  def decrypt_bytes(method)
    target_to_contexts = {}
    matches = method.body.scan(BYTES_DECRYPT)
    @optimizations[:string_decrypts] += matches.size if matches
    matches.each do |original, _, encrypted, _, class_name, method_signature, out_reg|
      target = @driver.make_target(
        class_name, method_signature, encrypted.bytes.to_a
      )
      target_to_contexts[target] = [] unless target_to_contexts.key?(target)
      target_to_contexts[target] << [original, out_reg]
    end

    target_to_contexts
  end

  def decrypt_multi_bytes(method)
    target_to_contexts = {}
    target_id_to_output = {}
    matches = method.body.scan(MULTI_BYTES_DECRYPT)
    @optimizations[:string_decrypts] += matches.size if matches
    matches.each do |original, iv_str, out_reg, iv_class_name, iv_method_signature, iv2_str, iv2_class_name, iv2_method_signature, dec_class_name, dec_method_signature|
      iv_bytes = @driver.run(iv_class_name, iv_method_signature, iv_str)
      enc_bytes = @driver.run(iv2_class_name, iv2_method_signature, iv_bytes, iv2_str)
      dec_bytes = @driver.run(dec_class_name, dec_method_signature, enc_bytes)
      dec_array = array_string_to_array(dec_bytes)
      dec_string = dec_array.pack('U*')

      target = { id: Digest::SHA256.hexdigest(original) }
      target_id_to_output[target[:id]] = ['success', dec_string]
      target_to_contexts[target] = [] unless target_to_contexts.key?(target)
      target_to_contexts[target] << [original, out_reg]
    end

    method_to_target_to_contexts = { method => target_to_contexts }
    Plugin.apply_outputs(target_id_to_output, method_to_target_to_contexts, MODIFIER)
  end

  def array_string_to_array(str)
    if str =~ /\A\[(?:\d+(?:,\d+)*)?\]\z/
      str = eval(str)
    else
      raise "Output is not in byte format; this frightens me: #{str}"
    end
    str
  end
end
