Gem::Specification.new do |s|
  s.name        = "rumx"
  s.summary     = 'Ruby Management Extensions'
  s.description = 'A Ruby version of JMX'
  s.authors     = ['Brad Pardee']
  s.email       = ['bradpardee@gmail.com']
  s.homepage    = 'http://github.com/ClarityServices/rumx'
  s.files       = Dir["{examples,lib}/**/*"] + %w(LICENSE.txt Rakefile History.md README.md)
  s.version     = '0.2.3'
  s.add_dependency 'sinatra'
  s.add_dependency 'haml'
  s.add_dependency 'json'
  s.add_development_dependency 'rack'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
end
