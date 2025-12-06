# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/builder/xcframework'

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/MessageSpies
RSpec.describe XCFrameworkCLI::Builder::XCFramework do
  let(:framework_name) { 'MySDK' }
  let(:output_dir) { 'build' }
  let(:builder) { described_class.new(framework_name: framework_name, output_dir: output_dir) }

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
      error_message: 'XCFramework creation failed'
    )
  end

  describe '#initialize' do
    it 'sets framework_name and output_dir' do
      expect(builder.framework_name).to eq(framework_name)
      expect(builder.output_dir).to eq(output_dir)
    end
  end

  describe '#create_xcframework' do
    let(:archive_results) do
      [
        {
          success: true,
          archive_path: 'build/MySDK-iOS.xcarchive',
          platform: 'ios'
        },
        {
          success: true,
          archive_path: 'build/MySDK-iOS-Simulator.xcarchive',
          platform: 'ios-simulator'
        }
      ]
    end

    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(XCFrameworkCLI::Xcodebuild::Wrapper).to receive(:execute_create_xcframework).and_return(success_result)
    end

    it 'creates XCFramework from successful archives' do
      result = builder.create_xcframework(archive_results)

      expect(result[:success]).to be true
      expect(result[:xcframework_path]).to eq('build/MySDK.xcframework')
      expect(result[:frameworks_count]).to eq(2)
    end

    it 'calls xcodebuild with correct frameworks' do
      expect(XCFrameworkCLI::Xcodebuild::Wrapper).to receive(:execute_create_xcframework).with(
        hash_including(
          frameworks: array_including(
            hash_including(path: 'build/MySDK-iOS.xcarchive/Products/Library/Frameworks/MySDK.framework'),
            hash_including(path: 'build/MySDK-iOS-Simulator.xcarchive/Products/Library/Frameworks/MySDK.framework')
          ),
          output: 'build/MySDK.xcframework'
        )
      )

      builder.create_xcframework(archive_results)
    end

    it 'includes debug symbols when requested' do
      expect(XCFrameworkCLI::Xcodebuild::Wrapper).to receive(:execute_create_xcframework).with(
        hash_including(
          frameworks: array_including(
            hash_including(
              path: 'build/MySDK-iOS.xcarchive/Products/Library/Frameworks/MySDK.framework',
              debug_symbols: 'build/MySDK-iOS.xcarchive/dSYMs/MySDK.framework.dSYM'
            )
          )
        )
      )

      builder.create_xcframework(archive_results, include_debug_symbols: true)
    end

    it 'excludes debug symbols when not requested' do
      result = builder.create_xcframework(archive_results, include_debug_symbols: false)

      # Verify that the frameworks array doesn't include debug_symbols keys
      expect(result[:success]).to be true
      expect(XCFrameworkCLI::Xcodebuild::Wrapper).to have_received(:execute_create_xcframework) do |args|
        args[:frameworks].each do |framework|
          expect(framework).not_to have_key(:debug_symbols)
        end
      end
    end

    it 'filters out failed archives' do
      mixed_results = [
        { success: true, archive_path: 'build/MySDK-iOS.xcarchive', platform: 'ios' },
        { success: false, archive_path: 'build/MySDK-iOS-Simulator.xcarchive', platform: 'ios-simulator' }
      ]

      allow(File).to receive(:exist?).and_return(true)

      result = builder.create_xcframework(mixed_results)

      expect(result[:success]).to be true
      expect(result[:frameworks_count]).to eq(1)
    end

    it 'returns error when no successful archives' do
      failed_results = [
        { success: false, archive_path: 'build/MySDK-iOS.xcarchive', platform: 'ios' }
      ]

      result = builder.create_xcframework(failed_results)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('No successful archives to create XCFramework from')
    end

    it 'returns error when frameworks not found in archives' do
      allow(File).to receive(:exist?).and_return(false)

      result = builder.create_xcframework(archive_results)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('No frameworks found in archives')
    end

    it 'returns error when xcodebuild fails' do
      allow(XCFrameworkCLI::Xcodebuild::Wrapper).to receive(:execute_create_xcframework).and_return(failure_result)

      result = builder.create_xcframework(archive_results)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('XCFramework creation failed')
    end

    it 'handles exceptions gracefully' do
      allow(File).to receive(:exist?).and_raise(StandardError.new('File system error'))

      result = builder.create_xcframework(archive_results)

      expect(result[:success]).to be false
      expect(result[:error]).to eq('File system error')
    end
  end

  describe '#xcframework_exists?' do
    it 'returns true when XCFramework exists' do
      allow(File).to receive(:directory?).with('path/to/MySDK.xcframework').and_return(true)
      expect(builder.xcframework_exists?('path/to/MySDK.xcframework')).to be true
    end

    it 'returns false when XCFramework does not exist' do
      allow(File).to receive(:directory?).with('path/to/MySDK.xcframework').and_return(false)
      expect(builder.xcframework_exists?('path/to/MySDK.xcframework')).to be false
    end
  end

  describe '#xcframework_info' do
    it 'returns info when XCFramework exists' do
      xcframework_path = 'build/MySDK.xcframework'
      info_plist = 'build/MySDK.xcframework/Info.plist'

      allow(File).to receive(:directory?).with(xcframework_path).and_return(true)
      allow(File).to receive(:exist?).with(info_plist).and_return(true)
      allow(Dir).to receive(:glob).and_return([])

      info = builder.xcframework_info(xcframework_path)

      expect(info[:path]).to eq(xcframework_path)
      expect(info[:name]).to eq(framework_name)
      expect(info[:info_plist]).to eq(info_plist)
      expect(info[:size]).to eq(0)
    end

    it 'returns nil when XCFramework does not exist' do
      allow(File).to receive(:directory?).and_return(false)

      info = builder.xcframework_info('nonexistent')
      expect(info).to be_nil
    end

    it 'returns nil when Info.plist does not exist' do
      allow(File).to receive_messages(directory?: true, exist?: false)

      info = builder.xcframework_info('build/MySDK.xcframework')
      expect(info).to be_nil
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/MessageSpies
