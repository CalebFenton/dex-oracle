require 'json'
require 'digest'
require 'open3'
require 'timeout'
require_relative 'resources'
require_relative 'logging'
require_relative 'utility'

class Driver
  include Logging

  UNESCAPES = {
    'a' => "\x07", 'b' => "\x08", 't' => "\x09",
    'n' => "\x0a", 'v' => "\x0b", 'f' => "\x0c",
    'r' => "\x0d", 'e' => "\x1b", '\\' => '\\',
    '"' => '"', "'" => "'"
  }.freeze
  UNESCAPE_REGEX = /\\(?:([#{UNESCAPES.keys.join}])|u([\da-fA-F]{4}))|\\0?x([\da-fA-F]{2})/

  OUTPUT_HEADER = '===ORACLE DRIVER OUTPUT==='.freeze
  DRIVER_CLASS = 'org.cf.oracle.Driver'.freeze

  def initialize(device_id, timeout = 60)
    @device_id = device_id
    @timeout = timeout

    device_str = device_id.empty? ? '' : "-s #{@device_id} "
    @adb_base = "adb #{device_str}%s"
    @driver_dir = get_driver_dir
    unless @driver_dir
      logger.error 'Unable to find writable driver directory. Make sure /data/local or /data/local/tmp exists and is writable.'
      exit -1
    end
    logger.debug "Using #{@driver_dir} as driver directory ..."
    @cmd_stub = "cd #{@driver_dir}; export CLASSPATH=#{@driver_dir}/od.zip; app_process /system/bin #{DRIVER_CLASS}"

    @cache = {}
  end

  def install(dex)
    has_java = Utility.which('java')
    raise 'Unable to find Java on the path.' unless has_java

    begin
      # Merge driver and target dex file
      # Congratulations. You're now one of the 5 people who've used this tool explicitly.
      raise "#{Resources.dx} does not exist and is required for DexMerger" unless File.exist?(Resources.dx)
      raise "#{Resources.driver_dex} does not exist" unless File.exist?(Resources.driver_dex)
      logger.debug("Merging input DEX (#{dex.path}) and driver DEX (#{Resources.driver_dex}) ...")
      # Zip merged dex and push to device
      logger.debug('Pushing merged driver to device ...')
      tz = Tempfile.new(%w(oracle-driver .zip))
      # Could pass tz to create_zip, but Windows doesn't let you rename if file open
      # And zip internally renames files when creating them
      tempzip_path = tz.path
      tz.close
      Utility.create_zip(tempzip_path, 'classes.dex' => Resources.driver_dex)
      adb("push #{tz.path} #{@driver_dir}/od.zip")

      tz2 = Tempfile.new(%w(oracle-driver .zip))
      tempzip_path = tz2.path
      tz2.close
      Utility.create_zip(tempzip_path, 'classes.dex' => dex)
      adb("push #{tz2.path} #{@driver_dir}/app.zip")
    rescue => e
      puts "Error installing driver: #{e}\n#{e.backtrace.join("\n\t")}"
    ensure
      tz.close if tz
      tz.unlink if tz
      tz2.close if tz2
      tz2.unlink if tz2
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
      raise e if retries > 3

      logger.debug("Driver execution failed. Taking a quick nap and retrying, Zzzzz ##{retries} / 3 ...")
      sleep 5
      retries += 1
      retry
    end

    output
  end

  def run_batch(batch)
    push_batch_targets(batch)
    retries = 1
    begin
      drive("#{@cmd_stub} @#{@driver_dir}/od-targets.json", true)
    rescue => e
      raise e if retries > 3 || !e.message.include?('Segmentation fault')

      # Maybe we just need to retry
      logger.debug("Driver execution segfaulted. Taking a quick nap and retrying, Zzzzz ##{retries} / 3 ...")
      sleep 5
      retries += 1
      retry
    end
    pull_batch_outputs
  end

  def make_target(class_name, signature, *args)
    method = SmaliMethod.new(class_name, signature)
    target = {
      className: method.class.tr('/', '.'),
      methodName: method.name,
      arguments: build_arguments(method.parameters, args)
    }
    # Identifiers are used to map individual inputs to outputs
    target[:id] = Digest::SHA256.hexdigest(target.to_json)

    target
  end

  private

  def push_batch_targets(batch)
    target_file = Tempfile.new(%w(oracle-targets .json))
    target_file << batch.to_json
    target_file.flush
    logger.info("Pushing #{batch.size} method targets to device ...")
    adb("push #{target_file.path} #{@driver_dir}/od-targets.json")
    target_file.close
    target_file.unlink
  end

  def get_driver_dir
    # On some older devices, /data/local is world writable
    # But on other devices, it's /data/local/tmp
    %w(/data/local /data/local/tmp).each do |dir|
      stdout = adb("shell -x ls #{dir}")
      next if stdout == "ls: #{dir}: Permission denied"
      next if stdout == "ls: #{dir}: No such file or directory"
      stdout = adb("shell ls #{dir}")
      next if stdout == "opendir failed, Permission denied"
      return dir
    end

    nil
  end

  def pull_batch_outputs
    output_file = Tempfile.new(['oracle-output', '.json'])
    logger.debug('Pulling batch results from device ...')
    adb("pull #{@driver_dir}/od-output.json #{output_file.path}")
    adb("shell rm #{@driver_dir}/od-output.json")
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
      status = Timeout.timeout(@timeout) do
        if silent
          Open3.popen3(cmd) { |_, stdout, stderr, _| [stdout.read, stderr.read] }
        else
          [`#{cmd}`, '']
        end
      end
    rescue => e
      raise e if retries > 3

      logger.debug("ADB command execution timed out, retrying #{retries} ...")
      sleep 5
      retries += 1
      retry
    end
  end

  def validate_output(full_cmd, full_output)
    output_lines = full_output.split(/\r?\n/)
    exit_code = output_lines.last.to_i
    if exit_code != 0
      # Non zero exit code would only imply adb command itself was flawed
      # app_process, dalvikvm, etc. don't propigate exit codes back
      raise "Command failed with #{exit_code}: #{full_cmd}\nOutput: #{full_output}"
    end

    # Successful driver run should include driver header
    # Otherwise it may be a Segmentation fault or Killed
    logger.debug("Full output: #{full_output.inspect}")
    output_lines.reject! { |e| e.start_with?('WARNING:') }
    header = output_lines[0]
    if header != OUTPUT_HEADER
      print "app_process execution failure, output: '#{full_output}'"
      exception = adb("shell cat #{@driver_dir}/od-exception.txt").strip
      unless exception.end_with?('No such file or directory')
        adb("shell rm #{@driver_dir}/od-exception.txt")
        raise exception
      end
    end

    output_lines[1..-2].join("\n").rstrip
  end

  def drive(cmd, batch = false)
    return @cache[cmd] if @cache.key?(cmd)

    full_cmd = "shell \"#{cmd}\"; echo $?"
    full_output = adb(full_cmd)
    output = validate_output(full_cmd, full_output)

    # The driver writes any actual exceptions to the filesystem
    # Need to check to make sure the output value is legitimate
    logger.debug('Checking if execution had any exceptions ...')
    exception = adb("shell cat #{@driver_dir}/od-exception.txt").strip
    unless exception.end_with?('No such file or directory')
      adb("shell rm #{@driver_dir}/od-exception.txt")
      raise exception
    end
    logger.debug('No exceptions found :)')

    # Cache successful results for single method invocations for speed!
    @cache[cmd] = output unless batch
    logger.debug("output = #{output}")

    output
  end

  def adb(cmd)
    adb_with_stderr(cmd)[0]
  end

  def adb_with_stderr(cmd)
    full_cmd = @adb_base % cmd
    stdout, stderr = exec(full_cmd, false)
    [stdout.rstrip, stderr.rstrip]
  end

  def build_command(class_name, method_name, parameters, args)
    class_name.tr!('/', '.') # Make valid Java class name
    class_name.gsub!('$', '\$') # inner classes
    method_name.gsub!('$', '\$') # synthetic method names
    target = "'#{class_name}' '#{method_name}'"
    target_args = build_arguments(parameters, args)
    "#{@cmd_stub} #{target} #{target_args * ' '}"
  end

  private

  def unescape(str)
    str.gsub(UNESCAPE_REGEX) do
      if Regexp.last_match[1]
        if Regexp.last_match[1] == '\\'
          Regexp.last_match[1]
        else
          UNESCAPES[Regexp.last_match[1]]
        end
      elsif Regexp.last_match[2] # escape \u0000 unicode
        [Regexp.last_match[2].hex].pack('U*')
      elsif Regexp.last_match[3] # escape \0xff or \xff
        [Regexp.last_match[3]].pack('H2')
      end
    end
  end

  def build_arguments(parameters, args)
    parameters.map.with_index { |o, i| build_argument(o, args[i]) }
  end

  def build_argument(parameter, argument)
    if parameter[0] == 'L'
      java_type = parameter[1..-2].tr('/', '.')
      if java_type == 'java.lang.String'
        # Need to unescape smali string to get the actual string
        # Converting to bytes just avoids any weird non-printable characters nonsense
        argument = "[#{unescape(argument).bytes.to_a.join(',')}]"
      end
      "#{java_type}:#{argument}"
    else
      argument = (argument == '1' ? 'true' : 'false') if parameter == 'Z'
      "#{parameter}:#{argument}"
    end
  end
end
