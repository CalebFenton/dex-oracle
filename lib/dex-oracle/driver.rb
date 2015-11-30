class Driver
  UNESCAPES = {
      'a' => "\x07", 'b' => "\x08", 't' => "\x09",
      'n' => "\x0a", 'v' => "\x0b", 'f' => "\x0c",
      'r' => "\x0d", 'e' => "\x1b", "\\\\" => "\x5c",
      "\"" => "\x22", "'" => "\x27"
  }
  UNESCAPE_REGEX = /\\(?:([#{UNESCAPES.keys.join}])|u([\da-fA-F]{4}))|\\0?x([\da-fA-F]{2})/

  def initialize(dir, device_id, use_dvz)
    @dir = dir
    @device_id = device_id
    @use_dvz = use_dvz
    @cache = {}
    @cmd_stub = "adb shell #{@use_dvz ? 'dvz -classpath' : 'dalvikvm -cp'} #{@dir} org.cf.OracleDriver"
  end

  def run(class_name, signature, *args)
    method = SmaliMethod.new(class_name, signature)
    cmd = build_command(method.class, method.name, method.parameters, args)
    puts "cmd is: " << cmd
    output = exec(cmd)
  end

  def exec(cmd)
    output = `cmd`
    output.inspect.gsub('\\', '\\\\\\\\')
  end

  private

  def self.unescape(str)
    str.gsub(UNESCAPE_REGEX) do
      if $1
        $1 == '\\' ? $1 : UNESCAPES[$1]
      elsif $2 # escape \u0000 unicode
        ["#$2".hex].pack('U*')
      elsif $3 # escape \0xff or \xff
        [$3].pack('H2')
      end
    end
  end

  def build_command(class_name, method_name, parameters, args)
    class_name.gsub!('/', '.') # Make valid Java class name
    target = "#{class_name} #{method_name}"
    target_args = parameters.map.with_index do |o, i|
      if o[0] == 'L'
        obj = o[1..-2].gsub('/', '.')
        arg = args[i]
        arg = "[#{Driver.unescape(arg).bytes.to_a.join(',')}]" if obj == 'java.lang.String'
        "'#{obj}:#{arg}'"
      else
        "'#{o}:#{args[i]}'"
      end
    end
    "#{@cmd_stub} #{target} #{target_args * ' '}"
  end
end
