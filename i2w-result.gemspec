require_relative 'lib/i2w/result/version'

Gem::Specification.new do |s|
  s.name        = 'i2w-result'
  s.version     = I2w::Result::VERSION

  s.required_ruby_version = '>= 3.0.0'

  s.authors     = ['Ian White']
  s.email       = ['ian.w.white@gmail.com']

  s.homepage    = 'https://github.com/i2w/result'
  s.summary     = 'A monadic result object'
  s.description = 'i2w-result defines a monadic result'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  s.metadata['homepage_uri'] = s.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  s.files = Dir['{lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'activemodel', '>= 6'
  s.add_development_dependency 'activesupport', '>= 6'
  s.add_development_dependency 'rake', '>= 13.0.3'
end
