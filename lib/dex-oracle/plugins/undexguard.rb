require 'logger'

class Undexguard < Plugin

  include CommonRegex

  STRING_LOOKUP_3INT = Regexp.new(
      '^[ \t]*(' <<
          ((CONST_NUMBER << '\s+') * 3) <<
          'invoke-static \{[vp]\d+, [vp]\d+, [vp]\d+\}, L([^;]+);->([^\(]+)\(III\)Ljava/lang/String;' <<
          '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')', Regexp::MULTILINE)

  STRING_LOOKUP_1INT = Regexp.new(
      '^[ \t]*(' <<
          CONST_NUMBER << '\s+' <<
          'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+)\(I\)Ljava/lang/String;' <<
          '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  STRING_DECRYPT = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+)\(Ljava/lang/String;\)Ljava/lang/String;' <<
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

  def self.process(driver, smali_file)
    @@logger = Logger.new(STDOUT)

    @@logger.debug("Undexguarding #{smali_file}")
    smali_file.methods.each do |method|
      @@logger.debug("Decrypting #{method.name}")
      Undexguard.lookup_strings_3int(driver, method)
      Undexguard.lookup_strings_1int(driver, method)
    end
  end

  private

  def self.lookup_strings_3int(driver, method)
    matches = method.body.scan(STRING_LOOKUP_3INT)
    matches.each do |original, arg1, arg2, arg3, class_name, method_signature, out_reg|
      output = driver.run(
        class_name, method_signature, arg1.to_i(16), arg2.to_i(16), arg3.to_i(16)
      )
      modification = "const-string #{out_reg}, #{output}"

      method.body.gsub!(original, modification)
    end
    method.modified = true unless matches.empty?
  end

  def self.lookup_strings_1int(driver, method)
    matches = method.body.scan(STRING_LOOKUP_1INT)
    matches.each do |original, arg1, class_name, method_signature, out_reg|
      output = driver.run(
        class_name, method_signature, arg1.to_i(16)
      )
      modification = "const-string #{out_reg}, #{output}"

      method.body.gsub!(original, modification)
    end
    method.modified = true unless matches.empty?
  end

  def self.decrypt(driver, method)

  end
end
