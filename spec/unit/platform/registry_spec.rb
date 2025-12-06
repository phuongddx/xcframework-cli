# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/platform/registry'

RSpec.describe XCFrameworkCLI::Platform::Registry do
  describe '.create' do
    it 'creates iOS platform' do
      platform = described_class.create('ios')
      expect(platform).to be_a(XCFrameworkCLI::Platform::IOS)
    end

    it 'creates iOS Simulator platform' do
      platform = described_class.create('ios-simulator')
      expect(platform).to be_a(XCFrameworkCLI::Platform::IOSSimulator)
    end

    it 'raises error for unsupported platform' do
      expect do
        described_class.create('macos')
      end.to raise_error(XCFrameworkCLI::UnsupportedPlatformError, /macos/)
    end
  end

  describe '.valid?' do
    it 'returns true for ios' do
      expect(described_class.valid?('ios')).to be true
    end

    it 'returns true for ios-simulator' do
      expect(described_class.valid?('ios-simulator')).to be true
    end

    it 'returns false for unsupported platform' do
      expect(described_class.valid?('macos')).to be false
    end

    it 'returns false for nil' do
      expect(described_class.valid?(nil)).to be false
    end
  end

  describe '.all_platforms' do
    it 'returns all supported platform identifiers' do
      platforms = described_class.all_platforms
      expect(platforms).to contain_exactly('ios', 'ios-simulator')
    end
  end

  describe '.all_instances' do
    it 'returns instances of all platforms' do
      instances = described_class.all_instances
      expect(instances).to all(be_a(XCFrameworkCLI::Platform::Base))
      expect(instances.size).to eq(2)
    end
  end

  describe '.platform_class' do
    it 'returns IOS class for ios' do
      expect(described_class.platform_class('ios')).to eq(XCFrameworkCLI::Platform::IOS)
    end

    it 'returns IOSSimulator class for ios-simulator' do
      expect(described_class.platform_class('ios-simulator')).to eq(XCFrameworkCLI::Platform::IOSSimulator)
    end

    it 'returns nil for unsupported platform' do
      expect(described_class.platform_class('macos')).to be_nil
    end
  end

  describe '.platform_info' do
    it 'returns information for all platforms' do
      info = described_class.platform_info
      expect(info).to be_a(Hash)
      expect(info.keys).to contain_exactly('ios', 'ios-simulator')

      ios_info = info['ios']
      expect(ios_info[:name]).to eq('iOS')
      expect(ios_info[:sdk]).to eq('iphoneos')
      expect(ios_info[:architectures]).to eq(['arm64'])
    end
  end

  describe '.validate_platforms' do
    it 'returns empty array for valid platforms' do
      invalid = described_class.validate_platforms(%w[ios ios-simulator])
      expect(invalid).to be_empty
    end

    it 'returns invalid platforms' do
      invalid = described_class.validate_platforms(%w[ios macos tvos])
      expect(invalid).to contain_exactly('macos', 'tvos')
    end
  end

  describe '.create_all' do
    it 'creates multiple platforms' do
      platforms = described_class.create_all(%w[ios ios-simulator])
      expect(platforms.size).to eq(2)
      expect(platforms[0]).to be_a(XCFrameworkCLI::Platform::IOS)
      expect(platforms[1]).to be_a(XCFrameworkCLI::Platform::IOSSimulator)
    end

    it 'raises error if any platform is invalid' do
      expect do
        described_class.create_all(%w[ios macos])
      end.to raise_error(XCFrameworkCLI::UnsupportedPlatformError, /macos/)
    end

    it 'includes valid platforms in error message' do
      expect do
        described_class.create_all(['invalid'])
      end.to raise_error(XCFrameworkCLI::UnsupportedPlatformError, /Valid platforms: ios, ios-simulator/)
    end
  end
end
