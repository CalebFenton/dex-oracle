class Driver
  def initialize(dir, use_dvz)
    @dir = dir
    @use_dvz = use_dvz
    @cache = {}
  end

  def run(method_signature, *args)
    cmd = build_command(method_signature, args)
  end

  private

  def build_command(method_signature, args)
    param_types = get_parameter_types(method_signature)
    cmd = @use_dvz ? "dvz -classpath" : "dalvikvm -cp"
    cmd = cmd << " #{@dir} OracleDriver"
  end
end
