class SmaliMethod
  attr_reader :parameters, :return_type, :class_name, :method_name

  PARAMETER_ISOLATOR = /\([^\)]+\)/
  PARAMETER_INDIVIDUATOR = /(\[*(?:[BCDFIJSZ]|L[^;]+;))/

  def initialize(method_descriptor)
    parse(method_descriptor)
  end

  private

  def parse(method_descriptor)

  end

  def get_parameter_types(parameter_string)

  end
end