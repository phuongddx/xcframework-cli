# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/platform/ios_simulator'

RSpec.describe XCFrameworkCLI::Platform::IOSSimulator do
  let(:platform) { described_class.new }

  describe '.platform_name' do
    it 'returns iOS Simulator' do
      expect(described_class.platform_name).to eq('iOS Simulator')
    end
  end

  describe '.platform_identifier' do
    it 'returns ios-simulator' do
      expect(described_class.platform_identifier).to eq('ios-simulator')
    end
  end

  describe '.sdk_name' do
    it 'returns iphonesimulator' do
      expect(described_class.sdk_name).to eq('iphonesimulator')
    end
  end

  describe '.destination' do
    it 'returns generic iOS Simulator destination' do
      expect(described_class.destination).to eq('generic/platform=iOS Simulator')
    end
  end

  describe '.valid_architectures' do
    it 'returns arm64 and x86_64' do
      expect(described_class.valid_architectures).to eq(%w[arm64 x86_64])
    end
  end

  describe '.default_deployment_target' do
    it 'returns 14.0' do
      expect(described_class.default_deployment_target).to eq('14.0')
    end
  end

  describe '#sdk_version_key' do
    it 'returns IPHONEOS_DEPLOYMENT_TARGET' do
      expect(platform.sdk_version_key).to eq('IPHONEOS_DEPLOYMENT_TARGET')
    end
  end

  describe '#build_settings' do
    it 'includes iOS-specific deployment target key' do
      settings = platform.build_settings
      expect(settings['IPHONEOS_DEPLOYMENT_TARGET']).to eq('14.0')
      expect(settings['ARCHS']).to eq('arm64 x86_64')
    end

    it 'allows custom architectures' do
      settings = platform.build_settings(architectures: ['arm64'])
      expect(settings['ARCHS']).to eq('arm64')
    end
  end

  describe '#supports_architecture?' do
    it 'supports arm64' do
      expect(platform.supports_architecture?('arm64')).to be true
    end

    it 'supports x86_64' do
      expect(platform.supports_architecture?('x86_64')).to be true
    end

    it 'does not support armv7' do
      expect(platform.supports_architecture?('armv7')).to be false
    end
  end

  describe '#to_s' do
    it 'returns readable string' do
      expect(platform.to_s).to eq('iOS Simulator (iphonesimulator)')
    end
  end
end
