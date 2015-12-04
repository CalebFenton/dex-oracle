require_relative 'smali_field'
require_relative 'smali_method'
require_relative 'logging'

class SmaliFile
  attr_reader :class, :super, :interfaces, :methods, :fields, :file_path, :content

  include Logging

  ACCESSOR = /(?:interface|public|protected|private|abstract|static|final|synchronized|transient|volatile|native|strictfp|synthetic|enum|annotation)/
  TYPE = /(?:[IJFDZBCV]|L[^;]+;)/
  CLASS = /^\.class (?:#{ACCESSOR} )+(L[^;]+;)/
  SUPER = /^\.super (L[^;]+;)/
  INTERFACE = /^\.implements (L[^;]+;)/
  FIELD = /^\.field (?:#{ACCESSOR} )+([^\s]+)$/
  METHOD = /^.method (?:#{ACCESSOR} )+([^\s]+)$/

  def initialize(file_path)
    @file_path = file_path
    @modified = false
    parse(file_path)
  end

  def update
    @methods.each do |m|
      next unless m.modified
      logger.debug("Updating method: #{m}")
      update_method(m)
      m.modified = false
    end
    File.open(@file_path, 'w') { |f| f.write(@content) }
  end

  def to_s
    @class
  end

  private

  def parse(file_path)
    @content = IO.read(file_path)
    @class = @content[CLASS, 1]
    @super = @content[SUPER, 1]
    @interfaces = []
    @content.scan(INTERFACE).each { |m| @interfaces << m.first }
    @fields = []
    @content.scan(FIELD).each { |m| @fields << SmaliField.new(@class, m.first) }
    @methods = []
    @content.scan(METHOD).each do |m|
      body_regex = build_method_regex(m.first)
      body = @content[body_regex, 1]
      @methods << SmaliMethod.new(@class, m.first, body)
    end
  end

  def build_method_regex(method_signature)
    /\.method (?:#{ACCESSOR} )+#{Regexp.escape(method_signature)}(.*)^\.end method/m
  end

  def update_method(method)
    body_regex = build_method_regex(method.signature)
    body = @content[body_regex, 1]
    @content.sub!(body, method.body)
  end
end

