require 'json'
require 'digest'
require 'Open3'
require 'timeout'
require_relative 'logging'
require_relative 'utility'

class Driver
  include Logging

  UNESCAPES = {
      'a' => "\x07", 'b' => "\x08", 't' => "\x09",
      'n' => "\x0a", 'v' => "\x0b", 'f' => "\x0c",
      'r' => "\x0d", 'e' => "\x1b", "\\\\" => "\x5c",
      "\"" => "\x22", "'" => "\x27"
  }
  UNESCAPE_REGEX = /\\(?:([#{UNESCAPES.keys.join}])|u([\da-fA-F]{4}))|\\0?x([\da-fA-F]{2})/

  OUTPUT_HEADER = '===ORACLE DRIVER OUTPUT==='
  DRIVER_DIR = '/data/local'
  DRIVER_CLASS = 'org.cf.oracle.Driver'
  DX_PATH = 'res/dx.jar'
  DRIVER_DEX_PATH = 'res/driver.dex'

  def initialize(device_id, timeout)
    @device_id = device_id
    @timeout = timeout

    device_str = device_id.empty? ? '' : "-s #{@device_id} "
    @adb_base = "adb #{device_str} %s"
    @cmd_stub = "export CLASSPATH=#{DRIVER_DIR}/od.zip; app_process /system/bin #{DRIVER_CLASS}"

    @cache = {}
  end

  def install(dex)
    raise 'Unable to find Java on the path.' unless Utility.which('java')

    begin
      # Merge driver and target dex file
      # Congratulations. You're now one of the 5 people who've used this tool explicitly.
      logger.debug("Merging #{dex.path} and driver dex ...")
      raise "#{DX_PATH} does not exist and is required for DexMerger" unless File.exist?(DX_PATH)
      raise "#{DRIVER_DEX_PATH} does not exist" unless File.exist?(DRIVER_DEX_PATH)
      tf = Tempfile.new(['oracle-driver', '.dex'])
      cmd = "java -cp #{DX_PATH} com.android.dx.merge.DexMerger #{tf.path} #{dex.path} #{DRIVER_DEX_PATH}"
      exec("#{cmd}")

      # Zip merged dex and push to device
      logger.debug("Pushing merged driver to device ...")
      tz = Tempfile.new(['oracle-driver', '.zip'])
      Utility.create_zip(tz.path, { 'classes.dex' => tf })
      adb("push #{tz.path} #{DRIVER_DIR}/od.zip")
    ensure
      tf.close
      tf.unlink
      tz.close
      tz.unlink
    end
  end

  def run(class_name, signature, *args)
    method = SmaliMethod.new(class_name, signature)
    cmd = build_command(method.class, method.name, method.parameters, args)
    output = nil

    retries = 1
    begin
      output = drive(cmd)
    rescue => e
      # If you slam an emulator or device with too many app_process commands,
      # it eventually gets angry and segmentation faults. No idea why.
      # This took many frustrating hours to figure out.
      if retries <= 3
        logger.debug("Driver execution failed. Taking a quick nap then retrying, Zzzzz ##{retries} / 3 ...")
        sleep 5
        retries += 1
        retry
      else
        raise e
      end
    end
  end

  def run_batch(batch)
    push_batch_targets(batch)
    drive("#{@cmd_stub} @#{DRIVER_DIR}/od-targets.json", true)
    pull_batch_outputs
  end

  def make_target(class_name, signature, *args)
    method = SmaliMethod.new(class_name, signature)
    target = {
      className: method.class.gsub('/', '.'),
      methodName: method.name,
      arguments: Driver.build_arguments(method.parameters, args)
    }
    # Identifiers are used to map individual inputs to outputs
    target[:id] = Digest::SHA256.hexdigest(target.to_json)

    target
  end

  private

  def push_batch_targets(batch)
    target_file = Tempfile.new(['oracle-targets', '.json'])
    target_file << batch.to_json
    target_file.flush
    logger.info("Pushing #{batch.size} method targets to device ...")
    adb("push #{target_file.path} #{DRIVER_DIR}/od-targets.json")
    target_file.close
    target_file.unlink
  end

  def pull_batch_outputs
    output_file = Tempfile.new(['oracle-output', '.json'])
    logger.debug("Pulling batch results from device ...")
    adb("pull #{DRIVER_DIR}/od-output.json #{output_file.path}")
    #adb("shell rm #{DRIVER_DIR}/od-output.json")
    outputs = JSON.parse(File.read(output_file.path))
    outputs.each { |_, (_, v2)| v2.gsub!(/(?:^"|"$)/, '') if v2.start_with?('"') }
    logger.debug("Pulled #{outputs.size} outputs.")
    output_file.close
    output_file.unlink
    outputs
  end

  def exec(cmd, silent = true)
    logger.debug("exec: #{cmd}")

    retries = 1
    begin
      status = Timeout::timeout(@timeout) do
        if !silent
          `#{cmd}`
        else
          Open3.popen3(cmd) { |_, stdout, _, _| stdout.read }
        end
      end
    rescue => e
      if retries <= 3
        logger.debug("ADB command execution timed out, retrying #{retries} ...")
        sleep 5
        retries += 1
        retry
      else
        raise
      end
    end
  end

  def drive(cmd, batch = false)
    return @cache[cmd] if @cache.has_key?(cmd)

    output = nil
    full_cmd = "shell \"#{cmd}\"; echo $?"
    output = adb(full_cmd)
    output_lines = output.split(/\r?\n/)
    exit_code = output_lines.last.to_i
    if exit_code != 0
      # Non zero exit code would only imply adb command itself was flawed
      # app_process, dalvikvm, etc. don't propigate exit codes back
      raise "Command failed with #{exit_code}: #{full_cmd}\nOutput: #{output}"
    end

    # The driver writes any actual exceptions to the filesystem
    # Need to check to make sure the output value is legitimate
    logger.debug("Checking if execution had any exceptions ...")
    exception = adb("shell cat #{DRIVER_DIR}/od-exception.txt").strip
    unless exception.end_with?('No such file or directory')
      adb("shell rm #{DRIVER_DIR}/od-exception.txt")
      raise exception
    end
    logger.debug("No exceptions found :)")

    # Successful driver run should include driver header
    # Otherwise it may be a Segmentation fault or Killed
    header = output_lines[0]
    logger.debug("Full output: #{output.inspect}")
    raise "app_process execution failure, output: '#{output}'" if header != OUTPUT_HEADER

    output = output_lines[1..-2].join("\n").rstrip
    # Cache successful results for single method invocations for speed!
    # Need to cache the original output
    @cache[cmd] = output unless batch
    logger.debug("output = #{output}")

    output
  end

  def adb(cmd)
    full_cmd = @adb_base % cmd
    exec(full_cmd).rstrip
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
    class_name.gsub!('$', '\$') # inner classes
    method_name.gsub!('$', '\$') # synthetic method names
    target = "'#{class_name}' '#{method_name}'"
    target_args = Driver.build_arguments(parameters, args)
    "#{@cmd_stub} #{target} #{target_args * ' '}"
  end

  def self.build_arguments(parameters, args)
    parameters.map.with_index do |o, i|
      build_argument(o, args[i])
    end
  end

  def self.build_argument(parameter, argument)
    if parameter[0] == 'L'
      java_type = parameter[1..-2].gsub('/', '.')
      if java_type == 'java.lang.String'
        # Need to unescape smali string to get the actual string
        # Converting to bytes just avoids any weird non-printable characters nonsense
        argument = "[#{Driver.unescape(argument).bytes.to_a.join(',')}]"
      end
      "#{java_type}:#{argument}"
    else
      argument = (argument == '1' ? 'true' : 'false') if parameter == 'Z'
      "#{parameter}:#{argument}"
    end
  end
end
