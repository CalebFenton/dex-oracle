require 'logger'

class CommonRegex
  CONST_NUMBER = 'const(?:\/\d+) [vp]\d+, (-?0x[a-f\d]+)'
  ESCAPE_STRING = '"(.*?)(?<!\\\\)"'
  CONST_STRING = 'const-string [vp]\d+, ' << ESCAPE_STRING << '.*'
  MOVE_RESULT_OBJECT = 'move-result-object ([vp]\d+)'
end
