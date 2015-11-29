# -*- encoding: utf-8 -*-
$:.push('lib')
require 'dex-oracle/version'

Gem::Specification.new do |s|
  s.name     = 'dex-oracle'
  s.version  = DexOracle::VERSION.dup
  s.date     = '2015-11-28'
  s.summary  = 'Pattern based Dalvik deoptimizer'
  s.email    = 'calebjfenton@gmail.com'
  s.homepage = 'https://github.com/CalebFenton/dex-oracle'
  s.authors  = ['Caleb Fenton']
  s.description = <<-EOF
DexOracle is a pattern based Dalvik deoptimizer which uses limited execution to improve semantic analysis.
EOF

  dependencies = [
#    [:runtime,     'mechanize',  '~> 2.7', '> 2.7.0'],
    [:development, 'rspec'],
  ]

  s.files         = Dir['**/*']
  s.test_files    = Dir['test/**/*'] + Dir['spec/**/*']
  s.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  s.require_paths = %w(lib res)

  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = '2.2'
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version

  dependencies.each do |type, name, pversion, version|
    if s.respond_to?("add_#{type}_dependency")
      s.send("add_#{type}_dependency", name, pversion, version)
    else
      s.add_dependency(name, pversion, version)
    end
  end
end
