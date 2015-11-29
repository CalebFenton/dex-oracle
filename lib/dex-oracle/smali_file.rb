require_relative 'smali_field'
require_relative 'smali_method'

class SmaliFile
  attr_reader :class, :super, :interfaces, :methods, :fields, :file_path

  ACCESSOR = /(?:interface|public|protected|private|abstract|static|final|synchronized|transient|volatile|native|strictfp|synthetic|enum|annotation)/
  TYPE = /(?:[IJFDZBCV]|L[^;]+;)/
  CLASS = /^\.class (?:#{ACCESSOR} )+(L[^;]+;)/
  SUPER = /^\.super (L[^;]+;)/
  INTERFACE = /^\.implements (L[^;]+;)/
  FIELD = /^\.field (?:#{ACCESSOR} )+([^\s]+)$/
  METHOD = /^.method (?:#{ACCESSOR} )+([^\s]+)$/

  def initialize(file_path)
    @file_path = file_path
    parse(file_path)
  end

  private

  def parse(file_path)
    content = IO.read(file_path)
    @class = content[CLASS, 1]
    @super = content[SUPER, 1]
    @interfaces = []
    content.scan(INTERFACE).each { |m| @interfaces << m.first }
    @fields = []
    content.scan(FIELD).each { |m| @fields << SmaliField.new(@class, m.first) }
    @methods = []
    content.scan(METHOD).each { |m| @methods << SmaliMethod.new(@class, m.first) }
  end

  def to_s
    @file_path
  end
end

