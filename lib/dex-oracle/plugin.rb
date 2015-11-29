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

  def self.register_plugins
    Object.constants.each do |klass|
      const = Kernel.const_get(klass)
      @plugins << const if const.respond_to?(:superclass) && const.superclass == Plugin
    end
  end
end
