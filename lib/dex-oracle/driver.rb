require 'json'
require 'digest'
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
    output = adb(cmd)
  end

  def make_batch_item(class_name, signature, *args)
    method = SmaliMethod.new(class_name, signature)
    item = {
      className: method.class.gsub('/', '.'),
      methodName: method.name,
      arguments: Driver.build_arguments(method.parameters, args)
    }
    # Identifiers are used to map individual inputs to individual outputs
    id = Digest::SHA256.hexdigest(item.to_json)
    item[:id] = id

    item
  end

  def run_batch(batch)
    `adb shell rm #{DRIVER_DIR}/od-targets.json`
    tf = Tempfile.new(['oracle-targets', '.json'])
    tf << batch.to_json
    tf.flush
    `adb push #{tf.path} #{DRIVER_DIR}/od-targets.json`

    adb("#{@cmd_stub} @#{DRIVER_DIR}/od-targets.json", false)
    `adb pull #{DRIVER_DIR}/od-output.json #{tf.path}`
    `adb shell rm #{DRIVER_DIR}/od-output.json`
    outputs = JSON.parse(File.read(tf.path))
    tf.close
    tf.unlink

    outputs
  end

  def adb(cmd, cache = true)
    puts "cmd = #{cmd}"

    output = nil
    full_cmd = @adb_base % cmd
    if cache
      @cache[cmd] = `#{full_cmd}`.rstrip unless @cache.has_key?(cmd)
      output = @cache[cmd]
    else
      output = `#{full_cmd}`.rstrip
    end

    output_lines = output.split("\n")
    exit_code = output_lines.last.to_i
    if exit_code != 0
      # Non zero exit code would only imply adb command itself was flawed
      # app_process, dalvikvm, etc. don't propigate exit codes back
      raise "Command failed with #{exit_code}: #{full_cmd}\nOutput: #{output}"
    end
    output = output_lines[0..-2].join("\n")

    # The driver writes any actual exceptions to the filesystem
    # Need to check to make sure the output value is legitimate
    exception = `adb shell cat #{DRIVER_DIR}/od-exception.txt`.strip
    unless exception.end_with?('No such file or directory')
      `adb shell rm #{DRIVER_DIR}/od-exception.txt`
      raise exception
    end

    puts "output = #{output}"

    output
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
    "#{@cmd_stub} #{target} #{target_args * ' '}"
  end

  def self.build_arguments(parameters, args)
    parameters.map.with_index do |o, i|
      if o[0] == 'L'
        obj = o[1..-2].gsub('/', '.')
        arg = args[i]
        arg = "[#{Driver.unescape(arg).bytes.to_a.join(',')}]" if obj == 'java.lang.String'
        "#{obj}:#{arg}"
      else
        "#{o}:#{args[i]}"
      end
    end
  end
end
