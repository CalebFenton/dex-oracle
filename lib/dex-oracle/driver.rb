require 'json'
require_relative 'utility'

class Driver
  UNESCAPES = {
      'a' => "\x07", 'b' => "\x08", 't' => "\x09",
      'n' => "\x0a", 'v' => "\x0b", 'f' => "\x0c",
      'r' => "\x0d", 'e' => "\x1b", "\\\\" => "\x5c",
      "\"" => "\x22", "'" => "\x27"
  }
  UNESCAPE_REGEX = /\\(?:([#{UNESCAPES.keys.join}])|u([\da-fA-F]{4}))|\\0?x([\da-fA-F]{2})/
  DRIVER_DIR = '/data/local'
  DRIVER_CLASS = 'org.cf.oracle.Driver'

  def initialize(device_id)
    @device_id = device_id

    device_str = device_id.empty? ? '' : "-s #{@device_id} "
    @adb_base = "adb shell #{device_str}\"%s\"; echo $?"
    @cmd_stub = "export CLASSPATH=#{DRIVER_DIR}/od.zip; app_process /system/bin #{DRIVER_CLASS}"

    @cache = {}
  end

  def run_single(class_name, signature, *args)
    method = SmaliMethod.new(class_name, signature)
    cmd = build_command(method.class, method.name, method.parameters, args)
    output = exec(cmd)
  end

  def add_batch(batch, class_name, signature, *args)
    method = SmaliMethod.new(class_name, signature)
    item = {
      className: method.class.gsub('/', '.'),
      methodName: method.name,
      arguments: Driver.build_arguments(method.parameters, args)
    }
    batch << item
  end

  def run_batch(batch)
    json = batch.to_json
    tf = Tempfile.new(['oracle', '.json'])
    File.open(tf, 'w') { |f| f.write(batch.to_json) }
    exec("adb push #{tf.path} #{DRIVER_DIR}/od-targets.json")
    tf.close
    tf.unlink
    exec(@adb_base % "#{@cmd_stub} @#{DRIVER_DIR}/od-targets.json")
  end

  def exec(cmd)
    puts "cmd = #{cmd}"
    @cache[cmd] = `#{cmd}`.rstrip unless @cache.has_key?(cmd)
    output = @cache[cmd]
    puts "output = #{output}"
    output
    exit -1
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
      `adb push #{tz.path} #{DRIVER_DIR}/od.zip`
    ensure
      tf.close
      tf.unlink
      tz.close
      tz.unlink
    end
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
    class_name.gsub!('$', '\$') # inner classes
    method_name.gsub!('$', '\$') # synthetic method names
    target = "'#{class_name}' '#{method_name}'"
    target_args = Driver.build_arguments(parameters, args)
    @adb_base % "#{@cmd_stub} #{target} #{target_args * ' '}"
  end

  def self.build_arguments(parameters, args)
    parameters.map.with_index do |o, i|
      if o[0] == 'L'
        obj = o[1..-2].gsub('/', '.')
        arg = args[i]
        arg = "[#{Driver.unescape(arg).bytes.to_a.join(',')}]" if obj == 'java.lang.String'
        "'#{obj}:#{arg}'"
      else
        "'#{o}:#{args[i]}'"
      end
    end
  end
end
