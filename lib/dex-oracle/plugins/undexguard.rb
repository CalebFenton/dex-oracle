require 'logger'

class Undexguard < Plugin
  STRING_LOOKUP = Regexp.new(
      '^[ \t]*(' <<
          ((CommonRegex::CONST_NUMBER << '\s+') * 3) <<
          'invoke-static \{[vp]\d+, [vp]\d+, [vp]\d+\}, L(.+?);->(.+?)\(III\)Ljava/lang/String;' <<
          '\s+' <<
          CommonRegex::MOVE_RESULT_OBJECT <<
          ')', Regexp::MULTILINE)

  STRING_DECRYPT = Regexp.new(
      '^[ \t]*(' <<
          CommonRegex::CONST_STRING << '\s+' <<
          'invoke-static \{[vp]\d+\}, L(.+?);->(.+?)\(Ljava\/lang\/String;\)Ljava\/lang\/String;' <<
          '\s+' <<
          CommonRegex::MOVE_RESULT_OBJECT <<
          ')')

  STRING_DECRYPT_3INT = Regexp.new(
      '^[ \t]*(' <<
          CommonRegex::CONST_NUMBER << '\s+' <<
          'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+)\(I\)Ljava\/lang\/String;' <<
          '\s+' <<
          CommonRegex::MOVE_RESULT_OBJECT <<
          ')')

  STRING_DECRYPT_ALT = Regexp.new(
      '^[ \t]*(' <<
          CommonRegex::CONST_STRING << '\s+' <<
          'new-instance ([vp]\d+), L.+?;\s+(?:move-object(?:\/from16)? [vp]\d+, [vp]\d+\s+)?' \
          'invoke-static {.+?\[B\s+' <<
          'move-result-object [vp]\d+\s+' <<
          CommonRegex::CONST_STRING << '\s+' <<
          'invoke-virtual {[vp]\d+}, Ljava\/lang\/String;->getBytes\(\)\[B\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\/String;\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\[B\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\[B\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-direct {.+?\(\[B\)V' <<
          ')')

  def self.process(smali_file)
    @@logger = Logger.new(STDOUT)

    @@logger.debug("Undexguarding #{smali_file}")
    smali_file.methods.each do |method|
      @@logger.debug("Decrypting #{method.name}")
      Undexguard.decrypt(method)
    end
  end

  private

  def self.decrypt(method)


  end
end
