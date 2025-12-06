# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/xcodebuild/wrapper'

RSpec.describe XCFrameworkCLI::Xcodebuild::Wrapper do
  let(:success_status) { instance_double(Process::Status, success?: true, exitstatus: 0) }
  let(:failure_status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

  describe '.execute' do
    it 'executes command and returns successful result' do
      allow(Open3).to receive(:capture3).with('echo', 'hello').and_return(['output', '', success_status])

      result = described_class.execute('echo', ['hello'])

      expect(result).to be_a(XCFrameworkCLI::Xcodebuild::Result)
      expect(result.success?).to be true
      expect(result.stdout).to eq('output')
      expect(result.exit_code).to eq(0)
    end

    it 'executes command and returns failed result' do
      allow(Open3).to receive(:capture3).with('false').and_return(['', 'error', failure_status])

      result = described_class.execute('false', [])

      expect(result.failure?).to be true
      expect(result.stderr).to eq('error')
      expect(result.exit_code).to eq(1)
    end

    it 'captures stdout and stderr' do
      allow(Open3).to receive(:capture3).and_return(['stdout output', 'stderr output', success_status])

      result = described_class.execute('command', ['arg'])

      expect(result.stdout).to eq('stdout output')
      expect(result.stderr).to eq('stderr output')
    end

    it 'stores the command string' do
      allow(Open3).to receive(:capture3).and_return(['', '', success_status])

      result = described_class.execute('xcodebuild', ['-version'])

      expect(result.command).to eq('xcodebuild -version')
    end
  end

  describe '.execute_archive' do
    it 'builds correct archive command' do
      allow(Open3).to receive(:capture3).with(
        'xcodebuild',
        'archive',
        '-project', 'MyApp.xcodeproj',
        '-scheme', 'MySDK',
        '-destination', 'generic/platform=iOS',
        '-archivePath', 'build/MySDK-iOS'
      ).and_return(['', '', success_status])

      result = described_class.execute_archive(
        project: 'MyApp.xcodeproj',
        scheme: 'MySDK',
        destination: 'generic/platform=iOS',
        archive_path: 'build/MySDK-iOS'
      )

      expect(result.success?).to be true
      expect(Open3).to have_received(:capture3)
    end

    it 'includes derived data path when provided' do
      allow(Open3).to receive(:capture3).with(
        'xcodebuild',
        'archive',
        '-project', 'MyApp.xcodeproj',
        '-scheme', 'MySDK',
        '-destination', 'generic/platform=iOS',
        '-archivePath', 'build/MySDK-iOS',
        '-derivedDataPath', 'build/DerivedData'
      ).and_return(['', '', success_status])

      described_class.execute_archive(
        project: 'MyApp.xcodeproj',
        scheme: 'MySDK',
        destination: 'generic/platform=iOS',
        archive_path: 'build/MySDK-iOS',
        derived_data_path: 'build/DerivedData'
      )

      expect(Open3).to have_received(:capture3)
    end

    it 'includes build settings' do
      allow(Open3).to receive(:capture3).with(
        'xcodebuild',
        'archive',
        '-project', 'MyApp.xcodeproj',
        '-scheme', 'MySDK',
        '-destination', 'generic/platform=iOS',
        '-archivePath', 'build/MySDK-iOS',
        'BUILD_LIBRARY_FOR_DISTRIBUTION=YES',
        'ARCHS=arm64',
        'SKIP_INSTALL=NO'
      ).and_return(['', '', success_status])

      described_class.execute_archive(
        project: 'MyApp.xcodeproj',
        scheme: 'MySDK',
        destination: 'generic/platform=iOS',
        archive_path: 'build/MySDK-iOS',
        build_settings: {
          'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
          'ARCHS' => 'arm64',
          'SKIP_INSTALL' => 'NO'
        }
      )

      expect(Open3).to have_received(:capture3)
    end
  end

  describe '.execute_create_xcframework' do
    it 'builds correct create-xcframework command' do
      allow(Open3).to receive(:capture3).with(
        'xcodebuild',
        '-create-xcframework',
        '-framework', 'build/MySDK-iOS.xcarchive/Products/Library/Frameworks/MySDK.framework',
        '-framework', 'build/MySDK-iOS-Simulator.xcarchive/Products/Library/Frameworks/MySDK.framework',
        '-output', 'SDKs/MySDK.xcframework'
      ).and_return(['', '', success_status])

      result = described_class.execute_create_xcframework(
        frameworks: [
          { path: 'build/MySDK-iOS.xcarchive/Products/Library/Frameworks/MySDK.framework' },
          { path: 'build/MySDK-iOS-Simulator.xcarchive/Products/Library/Frameworks/MySDK.framework' }
        ],
        output: 'SDKs/MySDK.xcframework'
      )

      expect(result.success?).to be true
      expect(Open3).to have_received(:capture3)
    end

    it 'includes debug symbols when provided' do
      allow(Open3).to receive(:capture3).with(
        'xcodebuild',
        '-create-xcframework',
        '-framework', 'build/MySDK-iOS.xcarchive/Products/Library/Frameworks/MySDK.framework',
        '-debug-symbols', 'build/MySDK-iOS.xcarchive/dSYMs/MySDK.framework.dSYM',
        '-output', 'SDKs/MySDK.xcframework'
      ).and_return(['', '', success_status])

      described_class.execute_create_xcframework(
        frameworks: [
          {
            path: 'build/MySDK-iOS.xcarchive/Products/Library/Frameworks/MySDK.framework',
            debug_symbols: 'build/MySDK-iOS.xcarchive/dSYMs/MySDK.framework.dSYM'
          }
        ],
        output: 'SDKs/MySDK.xcframework'
      )

      expect(Open3).to have_received(:capture3)
    end
  end

  describe '.execute_clean' do
    it 'builds correct clean command' do
      allow(Open3).to receive(:capture3).with(
        'xcodebuild',
        'clean',
        '-project', 'MyApp.xcodeproj',
        '-scheme', 'MySDK'
      ).and_return(['', '', success_status])

      result = described_class.execute_clean(
        project: 'MyApp.xcodeproj',
        scheme: 'MySDK'
      )

      expect(result.success?).to be true
      expect(Open3).to have_received(:capture3)
    end

    it 'includes derived data path when provided' do
      allow(Open3).to receive(:capture3).with(
        'xcodebuild',
        'clean',
        '-project', 'MyApp.xcodeproj',
        '-scheme', 'MySDK',
        '-derivedDataPath', 'build/DerivedData'
      ).and_return(['', '', success_status])

      described_class.execute_clean(
        project: 'MyApp.xcodeproj',
        scheme: 'MySDK',
        derived_data_path: 'build/DerivedData'
      )

      expect(Open3).to have_received(:capture3)
    end
  end

  describe '.available?' do
    it 'returns true when xcodebuild is available' do
      allow(Open3).to receive(:capture3).with('which', 'xcodebuild').and_return(['/usr/bin/xcodebuild', '', success_status])

      expect(described_class.available?).to be true
    end

    it 'returns false when xcodebuild is not available' do
      allow(Open3).to receive(:capture3).with('which', 'xcodebuild').and_return(['', '', failure_status])

      expect(described_class.available?).to be false
    end
  end

  describe '.version' do
    it 'returns version string when available' do
      version_output = "Xcode 15.0\nBuild version 15A240d"
      allow(Open3).to receive(:capture3).with('xcodebuild', '-version').and_return([version_output, '', success_status])

      expect(described_class.version).to eq('Xcode 15.0')
    end

    it 'returns nil when xcodebuild is not available' do
      allow(Open3).to receive(:capture3).with('xcodebuild', '-version').and_return(['', 'not found', failure_status])

      expect(described_class.version).to be_nil
    end
  end

  describe '.sdk_path' do
    it 'returns SDK path when available' do
      allow(Open3).to receive(:capture3).with('xcrun', '--sdk', 'iphoneos', '--show-sdk-path')
                                        .and_return(["/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS17.0.sdk\n", '', success_status])

      path = described_class.sdk_path('iphoneos')
      expect(path).to eq('/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS17.0.sdk')
    end

    it 'returns nil when SDK is not found' do
      allow(Open3).to receive(:capture3).with('xcrun', '--sdk', 'invalid', '--show-sdk-path')
                                        .and_return(['', 'SDK not found', failure_status])

      expect(described_class.sdk_path('invalid')).to be_nil
    end
  end

  describe '.list_sdks' do
    it 'returns list of available SDKs' do
      sdks_output = <<~OUTPUT
        iOS SDKs:
        	iOS 17.0                      	-sdk iphoneos17.0
        iOS Simulator SDKs:
        	Simulator - iOS 17.0          	-sdk iphonesimulator17.0
        macOS SDKs:
        	macOS 14.0                    	-sdk macosx14.0
      OUTPUT

      allow(Open3).to receive(:capture3).with('xcodebuild', '-showsdks').and_return([sdks_output, '', success_status])

      sdks = described_class.list_sdks
      expect(sdks).to contain_exactly('iphoneos17.0', 'iphonesimulator17.0', 'macosx14.0')
    end

    it 'returns empty array when command fails' do
      allow(Open3).to receive(:capture3).with('xcodebuild', '-showsdks').and_return(['', 'error', failure_status])

      expect(described_class.list_sdks).to eq([])
    end
  end
end
