require_relative '../logging'
require_relative '../utility'

class Undexguard < Plugin
  include Logging
  include CommonRegex

  STRING_LOOKUP_3INT = Regexp.new(
      '^[ \t]*(' <<
          ((CONST_NUMBER << '\s+') * 3) <<
          'invoke-static \{[vp]\d+, [vp]\d+, [vp]\d+\}, L([^;]+);->([^\(]+\(III\))Ljava/lang/String;' <<
          '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')', Regexp::MULTILINE)

  STRING_LOOKUP_1INT = Regexp.new(
      '^[ \t]*(' <<
          CONST_NUMBER << '\s+' <<
          'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+\(I\))Ljava/lang/String;' <<
          '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  STRING_DECRYPT = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+\(Ljava/lang/String;\))Ljava/lang/String;' <<
          '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  BYTES_DECRYPT = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          'invoke-virtual \{[vp]\d+\}, Ljava\/lang\/String;->getBytes\(\)\[B\s+' <<
          'move-result-object [vp]\d+\s+' <<
          'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+\(\[B\))Ljava/lang/String;\s+' <<
          MOVE_RESULT_OBJECT <<
        ')')

  MULTI_BYTES_DECRYPT = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          'new-instance ([vp]\d+), L[^;]+;\s+' <<
          'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+\(Ljava/lang/String;\))\[B\s+' <<
          'move-result-object [vp]\d+\s+' <<
          CONST_STRING << '\s+' <<
          'invoke-static \{[vp]\d+, [vp]\d+\}, L([^;]+);->([^\(]+\(\[BLjava/lang/String;\))\[B\s+' <<
          'move-result-object [vp]\d+\s+' <<
          'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+\(\[B\))\[B\s+' <<
          'move-result-object [vp]\d+\s+' <<
          'invoke-direct \{[vp]\d+, [vp]\d+\}, Ljava\/lang\/String;-><init>\(\[B\)V' <<
          ')')

  MODIFIER = lambda { |original, output, out_reg| "const-string #{out_reg}, \"#{output.split('').collect { |e| e.inspect[1..-2] }.join}\"" }

  def self.process(driver, smali_files, methods)
    method_to_target_to_contexts = {}
    methods.each do |method|
      logger.info("Undexguarding #{method.descriptor}, stage 1/2")
      target_to_contexts = {}
      target_to_contexts.merge!(Undexguard.lookup_strings_3int(driver, method))
      target_to_contexts.merge!(Undexguard.lookup_strings_1int(driver, method))
      target_to_contexts.merge!(Undexguard.decrypt_strings(driver, method))
      target_to_contexts.merge!(Undexguard.decrypt_bytes(driver, method))
      target_to_contexts.map { |k, v| v.uniq! }
      method_to_target_to_contexts[method] = target_to_contexts unless target_to_contexts.empty?
    end

    made_changes = false
    made_changes |= Plugin.apply_batch(driver, method_to_target_to_contexts, MODIFIER)

    methods.each do |method|
      logger.info("Undexguarding #{method.descriptor}, stage 2/2")
      made_changes |= Undexguard.decrypt_multi_bytes(driver, method)
    end

    made_changes
  end

  private

  def self.lookup_strings_3int(driver, method)
    target_to_contexts = {}
    matches = method.body.scan(STRING_LOOKUP_3INT)
    matches.each do |original, arg1, arg2, arg3, class_name, method_signature, out_reg|
      target = driver.make_target(
        class_name, method_signature, arg1.to_i(16), arg2.to_i(16), arg3.to_i(16)
      )
      target_to_contexts[target] = [] unless target_to_contexts.has_key?(target)
      target_to_contexts[target] << [original, out_reg]
    end

    target_to_contexts
  end

  def self.lookup_strings_1int(driver, method)
    target_to_contexts = {}
    matches = method.body.scan(STRING_LOOKUP_1INT)
    matches.each do |original, arg1, class_name, method_signature, out_reg|
      target = driver.make_target(
        class_name, method_signature, arg1.to_i(16)
      )
      target_to_contexts[target] = [] unless target_to_contexts.has_key?(target)
      target_to_contexts[target] << [original, out_reg]
    end

    target_to_contexts
  end

  def self.decrypt_strings(driver, method)
    target_to_contexts = {}
    matches = method.body.scan(STRING_DECRYPT)
    matches.each do |original, encrypted, class_name, method_signature, out_reg|
      target = driver.make_target(
        class_name, method_signature, encrypted
      )
      target_to_contexts[target] = [] unless target_to_contexts.has_key?(target)
      target_to_contexts[target] << [original, out_reg]
    end

    target_to_contexts
  end

  def self.decrypt_bytes(driver, method)
    target_to_contexts = {}
    matches = method.body.scan(BYTES_DECRYPT)
    matches.each do |original, encrypted, class_name, method_signature, out_reg|
      target = driver.make_target(
        class_name, method_signature, encrypted.bytes.to_a
      )
      target_to_contexts[target] = [] unless target_to_contexts.has_key?(target)
      target_to_contexts[target] << [original, out_reg]
    end

    target_to_contexts
  end

  def self.array_string_to_array(str)
      if str =~ /^\[(\d+(,|\]$))+/
        str = eval(str)
      else
        raise "Output is not in byte format, which frightens me: #{str}"
      end
      str
  end

  def self.decrypt_multi_bytes(driver, method)
    target_to_contexts = {}
    target_id_to_output = {}
    matches = method.body.scan(MULTI_BYTES_DECRYPT)
    matches.each do |original, iv_str, out_reg, iv_class_name, iv_method_signature,
        iv2_str, iv2_class_name, iv2_method_signature,
        dec_class_name, dec_method_signature|

      iv_bytes = driver.run(iv_class_name, iv_method_signature, iv_str)
      enc_bytes = driver.run(iv2_class_name, iv2_method_signature, iv_bytes, iv2_str)
      dec_bytes = driver.run(dec_class_name, dec_method_signature, enc_bytes)
      dec_array = array_string_to_array(dec_bytes)
      dec_string = dec_array.pack('U*')

      target = { id: Digest::SHA256.hexdigest(original) }
      target_id_to_output[target[:id]] = ['success', dec_string]
      target_to_contexts[target] = [] unless target_to_contexts.has_key?(target)
      target_to_contexts[target] << [original, out_reg]
    end

    method_to_target_to_contexts = { method => target_to_contexts }
    Plugin.apply_outputs(target_id_to_output, method_to_target_to_contexts, MODIFIER)
  end
end
