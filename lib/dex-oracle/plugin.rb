require 'set'

class Plugin
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
