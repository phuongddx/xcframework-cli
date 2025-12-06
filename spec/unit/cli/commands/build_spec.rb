# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/cli/commands/build'
require 'tempfile'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe XCFrameworkCLI::CLI::Commands::Build do
  let(:command) { described_class.new([], options) }
  let(:options) do
    {
      project: 'MySDK.xcodeproj',
      scheme: 'MySDK',
      framework_name: 'MySDK',
      output: 'build',
      platforms: %w[ios ios-simulator],
      clean: true,
      debug_symbols: true,
      verbose: false,
      quiet: false
    }
  end

  let(:orchestrator) { instance_double(XCFrameworkCLI::Builder::Orchestrator) }
  let(:successful_result) do
    {
      success: true,
      xcframework_path: 'build/MySDK.xcframework',
      archives: [
        { platform: 'ios', archive_path: 'build/MySDK-iOS.xcarchive' },
        { platform: 'ios-simulator', archive_path: 'build/MySDK-iOS-Simulator.xcarchive' }
      ],
      errors: []
    }
  end

  let(:failed_result) do
    {
      success: false,
      xcframework_path: nil,
      archives: [],
      errors: ['Build failed for iOS', 'Archive creation failed']
    }
  end

  before do
    allow(XCFrameworkCLI::Builder::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:build).and_return(successful_result)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:verbose=)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:quiet=)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:section)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:info)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:success)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:error)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:result)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:blank_line)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:debug)
  end

  describe '#execute' do
    context 'with command-line options' do
      it 'builds XCFramework successfully' do
        command.execute

        expect(XCFrameworkCLI::Builder::Orchestrator).to have_received(:new).with(
          project_path: 'MySDK.xcodeproj',
          scheme: 'MySDK',
          framework_name: 'MySDK',
          output_dir: 'build',
          platforms: %w[ios ios-simulator],
          clean: true,
          include_debug_symbols: true
        )
        expect(orchestrator).to have_received(:build)
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:success).with('Build completed successfully!')
      end

      it 'sets logger verbosity' do
        command.execute

        expect(XCFrameworkCLI::Utils::Logger).to have_received(:verbose=).with(false)
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:quiet=).with(false)
      end

      it 'displays build information' do
        command.execute

        expect(XCFrameworkCLI::Utils::Logger).to have_received(:section).with('Building XCFramework')
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:info).with('Project: MySDK.xcodeproj')
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:info).with('Scheme: MySDK')
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:info).with('Framework: MySDK')
      end

      it 'displays archive results' do
        command.execute

        expect(XCFrameworkCLI::Utils::Logger).to have_received(:result)
          .with('ios: build/MySDK-iOS.xcarchive', success: true)
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:result)
          .with('ios-simulator: build/MySDK-iOS-Simulator.xcarchive', success: true)
      end
    end

    context 'with missing required options' do
      let(:options) do
        {
          output: 'build',
          platforms: %w[ios ios-simulator],
          clean: true,
          debug_symbols: true,
          verbose: false,
          quiet: false
        }
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'exits with error message' do
        expect { command.execute }.to raise_error(SystemExit)

        expect(XCFrameworkCLI::Utils::Logger).to have_received(:error) do |message|
          expect(message).to include('Missing required arguments')
          expect(message).to include('--project')
          expect(message).to include('--scheme')
          expect(message).to include('--framework-name')
        end
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context 'with config file' do
      let(:config_file) { Tempfile.new(['test', '.yml']) }
      let(:config_content) do
        {
          project: {
            name: 'TestSDK',
            xcode_project: 'TestSDK.xcodeproj'
          },
          frameworks: [
            {
              name: 'TestSDK',
              scheme: 'TestSDK',
              platforms: %w[ios ios-simulator]
            }
          ],
          build: {
            output_dir: 'custom_build',
            clean_before_build: false
          }
        }
      end

      let(:options) do
        {
          config: config_file.path,
          output: 'build',
          platforms: %w[ios ios-simulator],
          clean: true,
          debug_symbols: true,
          verbose: false,
          quiet: false
        }
      end

      before do
        config_file.write(config_content.to_yaml)
        config_file.rewind
      end

      after do
        config_file.close
        config_file.unlink
      end

      it 'loads configuration from file' do
        command.execute

        expect(XCFrameworkCLI::Builder::Orchestrator).to have_received(:new).with(
          project_path: 'TestSDK.xcodeproj',
          scheme: 'TestSDK',
          framework_name: 'TestSDK',
          output_dir: 'custom_build',
          platforms: %w[ios ios-simulator],
          clean: false,
          include_debug_symbols: true
        )
      end
    end

    context 'when build fails' do
      before do
        allow(orchestrator).to receive(:build).and_return(failed_result)
      end

      it 'displays error messages and exits' do
        expect { command.execute }.to raise_error(SystemExit)

        expect(XCFrameworkCLI::Utils::Logger).to have_received(:error).with('Build failed!')
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:result)
          .with('Build failed for iOS', success: false)
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:result)
          .with('Archive creation failed', success: false)
      end
    end

    context 'when an exception occurs' do
      let(:error) do
        XCFrameworkCLI::BuildError.new(
          'Build process failed',
          suggestions: ['Check Xcode project', 'Verify scheme name']
        )
      end

      before do
        allow(orchestrator).to receive(:build).and_raise(error)
      end

      it 'handles the error gracefully' do
        expect { command.execute }.to raise_error(SystemExit)

        expect(XCFrameworkCLI::Utils::Logger).to have_received(:error).with('Build process failed')
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:info).with('Suggestions:')
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:info).with('  • Check Xcode project')
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:info).with('  • Verify scheme name')
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
