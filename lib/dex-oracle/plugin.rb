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
end
