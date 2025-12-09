# frozen_string_literal: true

require 'integration_helper'
require 'tmpdir'
require 'fileutils'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'CLI Build Integration', :integration do
  # Skip integration tests if xcodebuild is not available
  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    skip 'xcodebuild not available - skipping integration tests' unless system('which xcodebuild > /dev/null 2>&1')
  end
  # rubocop:enable RSpec/BeforeAfterAll

  let(:project_path) { File.expand_path('../../Example/SwiftyBeaver/SwiftyBeaver.xcodeproj', __dir__) }
  let(:scheme) { 'SwiftyBeaver-Package' }
  let(:framework_name) { 'SwiftyBeaver' }
  let(:output_dir) { Dir.mktmpdir('xckit-test') }
  let(:cli_path) { File.expand_path('../../bin/xckit', __dir__) }

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe 'building with command-line arguments' do
    # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    it 'creates XCFramework successfully' do
      # Run the CLI
      result = system(
        cli_path,
        'build',
        '--project', project_path,
        '--scheme', scheme,
        '--framework-name', framework_name,
        '--output', output_dir,
        '--platforms', 'ios', 'ios-simulator',
        '--clean',
        '--debug-symbols',
        out: File::NULL,
        err: File::NULL
      )

      expect(result).to be true

      # Verify archives were created (archives are named using scheme, not framework name)
      ios_archive = File.join(output_dir, "#{scheme}-iOS.xcarchive")
      simulator_archive = File.join(output_dir, "#{scheme}-iOS-Simulator.xcarchive")

      expect(File.exist?(ios_archive)).to be true
      expect(File.exist?(simulator_archive)).to be true

      # Verify XCFramework was created
      xcframework_path = File.join(output_dir, "#{framework_name}.xcframework")
      expect(File.exist?(xcframework_path)).to be true

      # Verify XCFramework structure
      info_plist = File.join(xcframework_path, 'Info.plist')
      expect(File.exist?(info_plist)).to be true

      # Verify frameworks exist for both platforms
      ios_framework = Dir.glob(File.join(xcframework_path, 'ios-*', "#{framework_name}.framework")).first
      simulator_framework = Dir.glob(File.join(xcframework_path, 'ios-*-simulator', "#{framework_name}.framework")).first

      expect(ios_framework).not_to be_nil
      expect(simulator_framework).not_to be_nil

      # Verify debug symbols
      ios_dsym = Dir.glob(File.join(xcframework_path, 'ios-*', 'dSYMs', "#{framework_name}.framework.dSYM")).first
      simulator_dsym = Dir.glob(File.join(xcframework_path, 'ios-*-simulator', 'dSYMs',
                                          "#{framework_name}.framework.dSYM")).first

      expect(ios_dsym).not_to be_nil
      expect(simulator_dsym).not_to be_nil
    end
    # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe 'building with config file' do
    let(:config_file) { File.join(output_dir, '.xcframework.yml') }
    let(:config_content) do
      <<~YAML
        project:
          name: SwiftyBeaver
          xcode_project: #{project_path}

        frameworks:
          - name: #{framework_name}
            scheme: #{scheme}
            platforms:
              - ios
              - ios-simulator

        build:
          output_dir: #{output_dir}
          clean_before_build: true
      YAML
    end

    before do
      FileUtils.mkdir_p(output_dir)
      File.write(config_file, config_content)
    end

    it 'creates XCFramework successfully' do
      # Run the CLI with config file
      result = system(
        cli_path,
        'build',
        '--config', config_file,
        '--debug-symbols',
        out: File::NULL,
        err: File::NULL
      )

      expect(result).to be true

      # Verify XCFramework was created
      xcframework_path = File.join(output_dir, "#{framework_name}.xcframework")
      expect(File.exist?(xcframework_path)).to be true
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  describe 'architecture validation' do
    it 'creates XCFramework with correct architectures' do
      # Run the CLI
      system(
        cli_path,
        'build',
        '--project', project_path,
        '--scheme', scheme,
        '--framework-name', framework_name,
        '--output', output_dir,
        '--platforms', 'ios', 'ios-simulator',
        out: File::NULL,
        err: File::NULL
      )

      xcframework_path = File.join(output_dir, "#{framework_name}.xcframework")

      # Find the iOS framework binary
      ios_framework = Dir.glob(File.join(xcframework_path, 'ios-*', "#{framework_name}.framework",
                                         framework_name)).first
      simulator_framework = Dir.glob(File.join(xcframework_path, 'ios-*-simulator', "#{framework_name}.framework",
                                               framework_name)).first

      # Check architectures using lipo
      if ios_framework
        ios_archs = `lipo -info "#{ios_framework}"`.strip
        expect(ios_archs).to include('arm64')
      end

      if simulator_framework
        sim_archs = `lipo -info "#{simulator_framework}"`.strip
        # Should contain arm64 and/or x86_64
        expect(sim_archs).to match(/arm64|x86_64/)
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
