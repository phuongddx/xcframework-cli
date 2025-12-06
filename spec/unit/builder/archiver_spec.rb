# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/builder/archiver'

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/VerifiedDoubles, RSpec/MessageSpies
RSpec.describe XCFrameworkCLI::Builder::Archiver do
  let(:project_path) { 'MyApp.xcodeproj' }
  let(:scheme) { 'MySDK' }
  let(:output_dir) { 'build' }
  let(:archiver) do
    described_class.new(
      project_path: project_path,
      scheme: scheme,
      output_dir: output_dir
    )
  end

  let(:success_result) do
    instance_double(
      XCFrameworkCLI::Xcodebuild::Result,
      success?: true,
      error_message: nil
    )
  end

  let(:failure_result) do
    instance_double(
      XCFrameworkCLI::Xcodebuild::Result,
      success?: false,
      error_message: 'Build failed'
    )
  end

  describe '#initialize' do
    it 'sets project_path, scheme, and output_dir' do
      expect(archiver.project_path).to eq(project_path)
      expect(archiver.scheme).to eq(scheme)
      expect(archiver.output_dir).to eq(output_dir)
    end

    it 'sets default derived_data_path' do
      expect(archiver.derived_data_path).to eq('build/DerivedData')
    end

    it 'accepts custom derived_data_path' do
      custom_archiver = described_class.new(
        project_path: project_path,
        scheme: scheme,
        output_dir: output_dir,
        derived_data_path: 'custom/path'
      )
      expect(custom_archiver.derived_data_path).to eq('custom/path')
    end
  end

  describe '#build_archive' do
    let(:ios_platform) do
      double(
        'Platform',
        platform_name: 'iOS',
        destination: 'generic/platform=iOS',
        valid_architectures: ['arm64'],
        default_deployment_target: '14.0',
        build_settings: {
          'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
          'ARCHS' => 'arm64',
          'SKIP_INSTALL' => 'NO'
        }
      )
    end

    before do
      allow(XCFrameworkCLI::Platform::Registry).to receive(:create).with('ios').and_return(ios_platform)
      allow(XCFrameworkCLI::Xcodebuild::Wrapper).to receive(:execute_archive).and_return(success_result)
      allow(Dir).to receive(:glob).and_return([])
    end

    it 'builds archive for iOS platform' do
      result = archiver.build_archive('ios')

      expect(result[:success]).to be true
      expect(result[:archive_path]).to eq('build/MySDK-iOS.xcarchive')
      expect(result[:platform]).to eq('ios')
      expect(result[:platform_name]).to eq('iOS')
    end

    it 'calls xcodebuild with correct parameters' do
      expect(XCFrameworkCLI::Xcodebuild::Wrapper).to receive(:execute_archive).with(
        hash_including(
          project: project_path,
          scheme: scheme,
          destination: 'generic/platform=iOS',
          archive_path: 'build/MySDK-iOS',
          derived_data_path: 'build/DerivedData'
        )
      )

      archiver.build_archive('ios')
    end

    it 'uses custom deployment target when provided' do
      allow(ios_platform).to receive(:build_settings).with(
        architectures: ['arm64'],
        deployment_target: '15.0'
      ).and_return({})

      archiver.build_archive('ios', deployment_target: '15.0')

      expect(ios_platform).to have_received(:build_settings).with(
        architectures: ['arm64'],
        deployment_target: '15.0'
      )
    end

    it 'returns failure result when build fails' do
      allow(XCFrameworkCLI::Xcodebuild::Wrapper).to receive(:execute_archive).and_return(failure_result)

      result = archiver.build_archive('ios')

      expect(result[:success]).to be false
      expect(result[:archive_path]).to be_nil
      expect(result[:error]).to eq('Build failed')
    end

    it 'handles exceptions gracefully' do
      allow(XCFrameworkCLI::Platform::Registry).to receive(:create).and_raise(StandardError.new('Platform error'))

      result = archiver.build_archive('ios')

      expect(result[:success]).to be false
      expect(result[:error]).to eq('Platform error')
    end
  end

  describe '#build_archives' do
    let(:ios_platform) do
      double(
        'Platform',
        platform_name: 'iOS',
        destination: 'generic/platform=iOS',
        valid_architectures: ['arm64'],
        default_deployment_target: '14.0',
        build_settings: {}
      )
    end

    let(:simulator_platform) do
      double(
        'Platform',
        platform_name: 'iOS Simulator',
        destination: 'generic/platform=iOS Simulator',
        valid_architectures: %w[arm64 x86_64],
        default_deployment_target: '14.0',
        build_settings: {}
      )
    end

    before do
      allow(XCFrameworkCLI::Platform::Registry).to receive(:create).with('ios').and_return(ios_platform)
      allow(XCFrameworkCLI::Platform::Registry).to receive(:create).with('ios-simulator').and_return(simulator_platform)
      allow(XCFrameworkCLI::Xcodebuild::Wrapper).to receive(:execute_archive).and_return(success_result)
      allow(Dir).to receive(:glob).and_return([])
    end

    it 'builds archives for multiple platforms' do
      results = archiver.build_archives(%w[ios ios-simulator])

      expect(results.size).to eq(2)
      expect(results[0][:platform]).to eq('ios')
      expect(results[1][:platform]).to eq('ios-simulator')
    end
  end

  describe '#archive_exists?' do
    it 'returns true when archive exists' do
      allow(File).to receive(:directory?).with('path/to/archive').and_return(true)
      expect(archiver.archive_exists?('path/to/archive')).to be true
    end

    it 'returns false when archive does not exist' do
      allow(File).to receive(:directory?).with('path/to/archive').and_return(false)
      expect(archiver.archive_exists?('path/to/archive')).to be false
    end
  end

  describe '#framework_path_in_archive' do
    it 'returns framework path when it exists' do
      archive_path = 'build/MySDK-iOS.xcarchive'
      expected_path = 'build/MySDK-iOS.xcarchive/Products/Library/Frameworks/MySDK.framework'

      allow(File).to receive(:exist?).with(expected_path).and_return(true)

      result = archiver.framework_path_in_archive(archive_path, 'MySDK')
      expect(result).to eq(expected_path)
    end

    it 'returns nil when framework does not exist' do
      allow(File).to receive(:exist?).and_return(false)

      result = archiver.framework_path_in_archive('archive', 'MySDK')
      expect(result).to be_nil
    end
  end

  describe '#dsym_path_in_archive' do
    it 'returns dSYM path when it exists' do
      archive_path = 'build/MySDK-iOS.xcarchive'
      expected_path = 'build/MySDK-iOS.xcarchive/dSYMs/MySDK.framework.dSYM'

      allow(File).to receive(:exist?).with(expected_path).and_return(true)

      result = archiver.dsym_path_in_archive(archive_path, 'MySDK')
      expect(result).to eq(expected_path)
    end

    it 'returns nil when dSYM does not exist' do
      allow(File).to receive(:exist?).and_return(false)

      result = archiver.dsym_path_in_archive('archive', 'MySDK')
      expect(result).to be_nil
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/VerifiedDoubles, RSpec/MessageSpies
