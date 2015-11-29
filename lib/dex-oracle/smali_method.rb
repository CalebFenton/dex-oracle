class SmaliMethod
  attr_reader :name, :class, :descriptor, :parameters, :return_type

  PARAMETER_ISOLATOR = /\([^\)]+\)/
  PARAMETER_INDIVIDUATOR = /(\[*(?:[BCDFIJSZ]|L[^;]+;))/

  def initialize(class_name, method_signature)
    @class = class_name
    @name = method_signature[/[^\(]+/]
    @return_type = method_signature[/[^\)$]+$/]
    @descriptor = "#{class_name}->#{method_signature}"
    parameter_string = method_signature[PARAMETER_ISOLATOR]
    @parameters = []
    parameter_string.scan(PARAMETER_INDIVIDUATOR).each do |m|
      @parameters << m.first
    end
  end

  def to_s
    @descriptor
  end

  def ==(o)
      o.class == self.class && o.state == state
  end

  def state
      [@parameters, @return_type, @class, @name, @descriptor]
  end
end
