require_relative '../logging'

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

  STRING_DECRYPT_ALT = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          'new-instance ([vp]\d+), L[^;]+;\s+' <<
          '(?:move-object(?:\/from16)? [vp]\d+, [vp]\d+\s+)?' <<
          'invoke-static {.+?\[B\s+' <<
          'move-result-object [vp]\d+\s+' <<
          CONST_STRING << '\s+' <<
          'invoke-virtual {[vp]\d+}, Ljava\/lang\/String;->getBytes\(\)\[B\s+' <<
          'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\/String;\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\[B\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\[B\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-direct {.+?\(\[B\)V' <<
          ')')

  MODIFIER = lambda { |original, output, out_reg| "const-string #{out_reg}, #{output}" }

  def self.process(driver, smali_files, methods)
    method_to_target_to_contexts = {}
    methods.each do |method|
      logger.info("Undexguarding #{method.descriptor}")
      target_to_contexts = {}
      target_to_contexts.merge!(Undexguard.lookup_strings_3int(driver, method))
      target_to_contexts.merge!(Undexguard.lookup_strings_1int(driver, method))
      target_to_contexts.merge!(Undexguard.decrypt_strings(driver, method))
      target_to_contexts.map { |k, v| v.uniq! }
      method_to_target_to_contexts[method] = target_to_contexts unless target_to_contexts.empty?
    end

    Plugin.apply_batch(driver, method_to_target_to_contexts, MODIFIER)
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
end
