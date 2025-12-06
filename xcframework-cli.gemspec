# frozen_string_literal: true

require_relative 'lib/xcframework_cli/version'

Gem::Specification.new do |spec|
  spec.name          = 'xcframework-cli'
  spec.version       = XCFrameworkCLI::VERSION
  spec.authors       = ['Phuong Doan Duy']
  spec.email         = ['phuong.doan@aavn.com']

  spec.summary       = 'A professional Ruby CLI tool for building XCFrameworks across all Apple platforms'
  spec.description   = <<~DESC
    XCFramework CLI is a framework-agnostic tool for building XCFrameworks for iOS, macOS, tvOS, 
    watchOS, visionOS, and Mac Catalyst. It provides a clean Ruby interface to xcodebuild with 
    support for resource bundles, custom accessors, and Artifactory publishing.
  DESC
  spec.homepage      = 'https://github.com/aavn/xcframework-cli'
  spec.license       = 'Proprietary'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/aavn/xcframework-cli'
  spec.metadata['changelog_uri'] = 'https://github.com/aavn/xcframework-cli/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob('{bin,lib,templates,config}/**/*') + %w[
    README.md
    CHANGELOG.md
    LICENSE
  ]
  spec.bindir        = 'bin'
  spec.executables   = ['xcframework-cli']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'colorize', '~> 1.1'
  spec.add_dependency 'dry-validation', '~> 1.10'
  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'tty-prompt', '~> 0.23'
  spec.add_dependency 'tty-spinner', '~> 0.9'

  # Development dependencies
  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'pry-byebug', '~> 3.10'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.20'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'yard', '~> 0.9'
end

