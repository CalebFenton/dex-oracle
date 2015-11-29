class Driver
  def initialize(dir, device_id, use_dvz)
    @dir = dir
    @device_id = device_id
    @use_dvz = use_dvz
    @cache = {}
    @cmd_stub = "adb shell #{@use_dvz ? 'dvz -classpath' : 'dalvikvm -cp'} #{@dir} OracleDriver"
  end

  def run(class_name, signature, *args)
    method = SmaliMethod.new(class_name, signature)
    cmd = build_command(method.class, method.signature, method.parameters, args)
    puts "cmd is: " << cmd
    output = '' # `cmd`
    output.inspect.gsub('\\', '\\\\\\\\')
  end

  private

  def build_command(class_name, signature, parameters, args)
    class_name.gsub!('/', '.') # Make valid Java class name
    target = "#{class_name} #{signature}"
    target_args = parameters.map.with_index { |o, i| "#{o}:#{args[i]}"}
    cmd = "#{@cmd_stub} #{target} #{target_args}"
  end
end
