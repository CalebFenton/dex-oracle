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
    unless parameter_string.nil?
      parameter_string.scan(PARAMETER_INDIVIDUATOR).each do |m|
        @parameters << m.first
      end
    end
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
