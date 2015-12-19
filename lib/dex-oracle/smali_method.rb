class SmaliMethod
  attr_accessor :modified, :body
  attr_reader :name, :class, :descriptor, :signature, :parameters, :return_type

  PARAMETER_ISOLATOR = /\([^\)]+\)/
  PARAMETER_INDIVIDUATOR = /(\[*(?:[BCDFIJSZ]|L[^;]+;))/

  def initialize(class_name, signature, body = nil)
    @modified = false
    @class = class_name
    @name = signature[/[^\(]+/]
    @body = body
    @return_type = signature[/[^\)$]+$/]
    @descriptor = "#{class_name}->#{signature}"
    @signature = signature
    @parameters = []
    parameter_string = signature[PARAMETER_ISOLATOR]
    return if parameter_string.nil?
    parameter_string.scan(PARAMETER_INDIVIDUATOR).each { |m| @parameters << m.first }
  end

  def to_s
    @descriptor
  end

  def ==(other)
      other.class == self.class && other.state == state
  end

  def state
      [@name, @class, @descriptor, @parameters, @return_type, @modified, @body]
  end
end
