require 'zip'

class Utility
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

  def self.create_zip(zip, name_to_file)
    Zip::File.open(zip, Zip::File::CREATE) do |zf|
      name_to_file.each { |n, f| zf.add(n, f) }
    end
  end

  def self.extract_file(zip, name, dest)
    Zip::File.open(zip) do |zf|
      zf.each do |e|
        next unless e.name == name
        e.extract(dest) { true } # overwrite
        break
      end
    end
  end

  def self.update_zip(zip, name, target)
    Zip::File.open(zip) do |zf|
      zf.remove(name)
      zf.add(name, target.path)
    end
  end
end
