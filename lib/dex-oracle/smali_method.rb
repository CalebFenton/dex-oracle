class SmaliMethod
  attr_accessor :modified, :body
  attr_reader :name, :class, :descriptor, :signature, :parameters, :return_type

  PARAMETER_ISOLATOR = /\([^\)]+\)/
  PARAMETER_INDIVIDUATOR = /(\[*(?:[BCDFIJSZ]|L[^;]+;))/

  def initialize(class_name, method_signature, body)
    @modified = false
    @class = class_name
    @name = method_signature[/[^\(]+/]
    @return_type = method_signature[/[^\)$]+$/]
    @descriptor = "#{class_name}->#{method_signature}"
    @signature = method_signature
    parameter_string = method_signature[PARAMETER_ISOLATOR]
    @parameters = []
    parameter_string.scan(PARAMETER_INDIVIDUATOR).each do |m|
      @parameters << m.first
    end
    @body = body
  end

  def to_s
    @descriptor
  end

  def ==(o)
      o.class == self.class && o.state == state
  end

  def state
      [@name, @class, @descriptor, @parameters, @return_type, @modified, @body]
  end
end
