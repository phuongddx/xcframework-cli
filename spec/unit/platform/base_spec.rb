# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/platform/base'

RSpec.describe XCFrameworkCLI::Platform::Base do
  # Create a concrete test class since Base is abstract
  let(:test_platform_class) do
    Class.new(described_class) do
      def self.platform_name
        'TestPlatform'
      end

      def self.platform_identifier
        'test'
      end

      def self.sdk_name
        'testplatform'
      end

      def self.destination
        'generic/platform=Test'
      end

      def self.valid_architectures
        %w[arm64 x86_64]
      end

      def self.default_deployment_target
        '14.0'
      end

      def sdk_version_key
        'TEST_DEPLOYMENT_TARGET'
      end
    end
  end

  let(:platform) { test_platform_class.new }

  describe '.platform_name' do
    it 'raises NotImplementedError for base class' do
      expect { described_class.platform_name }.to raise_error(NotImplementedError)
    end

    it 'returns platform name for concrete class' do
      expect(test_platform_class.platform_name).to eq('TestPlatform')
    end
  end

  describe '#initialize' do
    it 'sets the name from class method' do
      expect(platform.name).to eq('TestPlatform')
    end
  end

  describe '#platform_identifier' do
    it 'delegates to class method' do
      expect(platform.platform_identifier).to eq('test')
    end
  end

  describe '#sdk_name' do
    it 'delegates to class method' do
      expect(platform.sdk_name).to eq('testplatform')
    end
  end

  describe '#destination' do
    it 'delegates to class method' do
      expect(platform.destination).to eq('generic/platform=Test')
    end
  end

  describe '#valid_architectures' do
    it 'delegates to class method' do
      expect(platform.valid_architectures).to eq(%w[arm64 x86_64])
    end
  end

  describe '#default_deployment_target' do
    it 'delegates to class method' do
      expect(platform.default_deployment_target).to eq('14.0')
    end
  end

  describe '#supports_architecture?' do
    it 'returns true for valid architecture' do
      expect(platform.supports_architecture?('arm64')).to be true
    end

    it 'returns false for invalid architecture' do
      expect(platform.supports_architecture?('armv7')).to be false
    end

    it 'accepts symbols' do
      expect(platform.supports_architecture?(:arm64)).to be true
    end
  end

  describe '#validate_architectures' do
    it 'returns true for valid architectures' do
      expect(platform.validate_architectures(%w[arm64 x86_64])).to be true
    end

    it 'raises error for invalid architectures' do
      expect do
        platform.validate_architectures(%w[arm64 armv7])
      end.to raise_error(XCFrameworkCLI::InvalidArchitectureError, /armv7/)
    end
  end

  describe '#build_settings' do
    it 'returns default build settings' do
      settings = platform.build_settings
      expect(settings['ARCHS']).to eq('arm64 x86_64')
      expect(settings['BUILD_LIBRARY_FOR_DISTRIBUTION']).to eq('YES')
      expect(settings['SKIP_INSTALL']).to eq('NO')
      expect(settings['TEST_DEPLOYMENT_TARGET']).to eq('14.0')
    end

    it 'accepts custom architectures' do
      settings = platform.build_settings(architectures: ['arm64'])
      expect(settings['ARCHS']).to eq('arm64')
    end

    it 'accepts custom deployment target' do
      settings = platform.build_settings(deployment_target: '15.0')
      expect(settings['TEST_DEPLOYMENT_TARGET']).to eq('15.0')
    end

    it 'validates architectures' do
      expect do
        platform.build_settings(architectures: ['armv7'])
      end.to raise_error(XCFrameworkCLI::InvalidArchitectureError)
    end
  end

  describe '#sdk_path' do
    it 'resolves SDK path using xcrun' do
      allow(platform).to receive(:execute_command).and_return('/path/to/sdk')

      expect(platform.sdk_path).to eq('/path/to/sdk')
    end

    it 'caches SDK path' do
      allow(platform).to receive(:execute_command).and_return('/path/to/sdk')

      platform.sdk_path
      platform.sdk_path

      expect(platform).to have_received(:execute_command).once
    end

    it 'raises error if xcrun fails' do
      allow(platform).to receive(:execute_command).and_return(nil)

      expect { platform.sdk_path }.to raise_error(XCFrameworkCLI::PlatformError, /Failed to resolve SDK path/)
    end

    it 'raises error if xcrun returns empty string' do
      allow(platform).to receive(:execute_command).and_return('')

      expect { platform.sdk_path }.to raise_error(XCFrameworkCLI::PlatformError, /Failed to resolve SDK path/)
    end
  end

  describe '#to_s' do
    it 'returns readable string' do
      expect(platform.to_s).to eq('TestPlatform (testplatform)')
    end
  end
end
