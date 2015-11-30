require_relative 'utility'

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
    @cmd_stub = "adb shell #{@use_dvz ? 'dvz -classpath' : 'dalvikvm -cp'} #{@dir}/od.zip org.cf.driver.OracleDriver"
  end

  def run(class_name, signature, *args)
    method = SmaliMethod.new(class_name, signature)
    cmd = build_command(method.class, method.name, method.parameters, args)
    output = exec(cmd)
  end

  def exec(cmd)
    puts "cmd = #{cmd}"
    @cache[cmd] = `#{cmd}`.rstrip unless @cache.has_key?(cmd)
    output = @cache[cmd]
    puts "output = #{output}"
    output
    #output.inspect.gsub('\\', '\\\\\\\\')
  end

  def install(dex)
    raise 'Unable to find Java on the path.' unless Utility.which('java')

    begin
      # Merge driver and target dex file
      tf = Tempfile.new(['oracle-driver', '.dex'])
      cmd = "java -cp resources/dx.jar com.android.dx.merge.DexMerger #{tf.path} #{dex.path} resources/driver.dex"
      `#{cmd}`

      # Zip merged dex and push to device
      tz = Tempfile.new(['oracle-driver', '.zip'])
      Utility.create_zip(tz.path, { 'classes.dex' => tf })
      `adb push #{tz.path} #{@dir}/od.zip`

      # Must execute once with dalvikvm before dvz will work
      `#{build_cmd_stub(false)}` if @use_dvz
    ensure
      tf.close
      tf.unlink
      tz.close
      tz.unlink
    end
  end

  private

  def self.build_cmd_stub(use_dvz)
    "adb shell #{use_dvz ? 'dvz -classpath' : 'dalvikvm -cp'} #{@dir}/od.zip org.cf.driver.OracleDriver"
  end

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
    class_name.gsub!('$', '\$')
    target = "'#{class_name}' '#{method_name}'"
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
