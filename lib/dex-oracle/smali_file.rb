class SmaliFile
  attr_reader :super, :interfaces, :methods, :fields

  def initialize(file_path)
    parse(file_path)
  end

  private

  def parse(file_path)

  end
end

