class Undexguard < Plugin
  CONST_NUMBER = 'const(?:\/\d+) [vp]\d+, (-?0x[a-f\d]+)'
  ESCAPE_STRING = '"(.*?)(?<!\\\\)"'
  CONST_STRING = 'const-string [vp]\d+, ' << ESCAPE_STRING << '.*'
  MOVE_RESULT_OBJECT = 'move-result-object ([vp]\d+)'
  CLASS_FOR_NAME = 'invoke-static \{[vp]\d+\}, Ljava\/lang\/Class;->forName\(Ljava\/lang\/String;\)Ljava\/lang\/Class;'

  STRING_LOOKUP = Regexp.new(
      '^[ \t]*(' <<
          ((CONST_NUMBER << '\s+') * 3) <<
          'invoke-static \{[vp]\d+, [vp]\d+, [vp]\d+\}, L(.+?);->(.+?)\(III\)Ljava/lang/String;' <<
          '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')', Regexp::MULTILINE)

  CONST_CLASS_REGEX = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          CLASS_FOR_NAME << '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  STRING_DECRYPT = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          'invoke-static \{[vp]\d+\}, L(.+?);->(.+?)\(Ljava\/lang\/String;\)Ljava\/lang\/String;' <<
          '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  STRING_DECRYPT_3INT = Regexp.new(
      '^[ \t]*(' <<
          CONST_NUMBER << '\s+' <<
          'invoke-static \{[vp]\d+\}, L([^;]+);->([^\(]+)\(I\)Ljava\/lang\/String;' <<
          '\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  STRING_DECRYPT_ALT = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          'new-instance ([vp]\d+), L.+?;\s+(?:move-object(?:\/from16)? [vp]\d+, [vp]\d+\s+)?' \
          'invoke-static {.+?\[B\s+' <<
          'move-result-object [vp]\d+\s+' <<
          CONST_STRING << '\s+' <<
          'invoke-virtual {[vp]\d+}, Ljava\/lang\/String;->getBytes\(\)\[B\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\/String;\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\[B\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-static {.+?\[B\s+' << 'move-result-object [vp]\d+\s+' <<
          'invoke-direct {.+?\(\[B\)V' <<
          ')')


  VIRTUAL_FIELD_LOOKUP = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          'invoke-static \{[vp]\d+\}, Ljava\/lang\/Class;->forName\(Ljava\/lang\/String;\)Ljava\/lang\/Class;\s+' <<
          MOVE_RESULT_OBJECT << '\s+' <<
          CONST_STRING << '\s+' <<
          'invoke-virtual \{[vp]\d+, [vp]\d+\}, Ljava\/lang\/Class;->getField\(Ljava\/lang\/String;\)Ljava\/lang\/reflect\/Field;\s+' <<
          MOVE_RESULT_OBJECT << '\s+' <<
          'invoke-virtual \{[vp]\d+, ([vp]\d+)\}, Ljava\/lang\/reflect\/Field;->get\(Ljava\/lang\/Object;\)Ljava\/lang\/Object;\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  STATIC_FIELD_LOOKUP = Regexp.new(
      '^[ \t]*(' <<
          CONST_STRING << '\s+' <<
          CLASS_FOR_NAME << '\s+' <<
          MOVE_RESULT_OBJECT << '\s+' <<
          CONST_STRING <<
          'invoke-virtual \{[vp]\d+, [vp]\d+\}, Ljava\/lang\/Class;->getField\(Ljava\/lang\/String;\)Ljava\/lang\/reflect\/Field;\s+' <<
          MOVE_RESULT_OBJECT << '\s+' <<
          'const/4 [vp]\d+, 0x0\s+' <<
          'invoke-virtual \{[vp]\d+, ([vp]\d+)\}, Ljava\/lang\/reflect\/Field;->get\(Ljava\/lang\/Object;\)Ljava\/lang\/Object;\s+' <<
          MOVE_RESULT_OBJECT <<
          ')')

  def process(smali_file)

  end

  private

  def decrypt_string(method_body)

  end
end
