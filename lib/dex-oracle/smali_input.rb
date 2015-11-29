class SmaliInput
  attr_reader :temporary, :dir

  DEX_MAGIC = [0x64, 0x65, 0x78]
  PK_ZIP_MAGIC = [0x50, 0x4b, 0x3]

  def initialize(input)
    unpack(input)
  end

  private

  def unpack(input)
    if File.directory?(input)
      @temporary = false
      @dir = input
      return
    end

    magic = File.open(input) { |f| f.read(3) }.bytes.to_a
    case magic
    when PK_ZIP_MAGIC, DEX_MAGIC
      @temporary = true
      baksmali(input)
    else
      raise "Unrecognized file type for: #{input}, magic=#{magic.inspect}"
    end
  end

  def baksmali(input)
    raise 'Baksmali could not be found on the path.' if SmaliInput.which('baksmali').nil?
    @dir = Dir.mktmpdir
    cmd = "baksmali #{input} -o #{@dir}"
    SmaliInput.run(cmd)
  end

  def self.run(cmd)
    `#{cmd}`
  end

  def self.which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each do |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable?(exe) && !File.directory?(exe)
      end
    end
    nil
  end
end
