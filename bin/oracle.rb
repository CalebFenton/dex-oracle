#!/usr/bin/env ruby
require 'optparse'

require_relative '../lib/oracle'
require_relative '../lib/oracle/smali_factory'

options = {
    :dir => '/data/local',
    :device_id => nil,
}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage #{File.basename($0)} [opts] <apk / dex / smali files>"
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end

  opts.on('-d', '--dir DIR', "Writable location to execute driver, default=\"#{options[:dir]}\"") do |dir|
    options[:dir] = dir
  end

  opts.on('-i', '--device-id', "Device ID for driver execution") do |id|
    options[:device_id] = id
  end
end

optparse.parse!

if ARGV.size < 1
  puts optparse.help()
  exit
end

input = ARGV[0]
smali_files = SmaliFactory.build(input)

start = Time.now
oracle = Oracle.new(smali_files)

oracle.divine

puts "Time elapsed #{Time.now - start} seconds"
