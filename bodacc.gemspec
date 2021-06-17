# frozen_string_literal: true

require_relative 'lib/bodacc/version'

Gem::Specification.new do |spec|
  spec.name          = 'bodacc'
  spec.version       = Bodacc::VERSION
  spec.authors       = ['Jonathan PHILIPPE']
  spec.email         = ['jonathan.philippe@metainnovative.net']

  spec.summary       = %q{}
  spec.description   = %q{}
  spec.homepage      = 'https://github.com/metainnovative/bodacc'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/metainnovative/bodacc'
    spec.metadata['changelog_uri'] = 'https://github.com/metainnovative/bodacc/CHANGELOG.md'
  end

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop'
  spec.add_dependency 'nokogiri', '~> 1.6', '>= 1.6.6.2'
end
