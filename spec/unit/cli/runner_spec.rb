# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/cli/runner'

RSpec.describe XCFrameworkCLI::CLI::Runner do
  let(:runner) { described_class.new }

  before do
    allow(XCFrameworkCLI::Utils::Logger).to receive(:error)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:info)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:blank_line)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:debug)
    allow(XCFrameworkCLI::Utils::Logger).to receive(:verbose)
  end

  describe '.exit_on_failure?' do
    it 'returns true' do
      expect(described_class.exit_on_failure?).to be true
    end
  end

  describe '#version' do
    it 'displays version information' do
      expect { runner.version }.to output(/XCFramework CLI v#{XCFrameworkCLI::VERSION}/).to_stdout
    end

    it 'displays description' do
      expect { runner.version }.to output(/A professional Ruby CLI tool/).to_stdout
    end
  end

  describe '#help' do
    context 'without command' do
      it 'displays general help' do
        expect { runner.help }.to output(/XCFramework CLI - Build XCFrameworks/).to_stdout
      end

      it 'displays usage information' do
        expect { runner.help }.to output(/USAGE:/).to_stdout
      end

      it 'displays available commands' do
        output = capture_stdout { runner.help }
        expect(output).to include('build')
        expect(output).to include('version')
        expect(output).to include('help')
      end

      it 'displays global options' do
        output = capture_stdout { runner.help }
        expect(output).to include('--verbose')
        expect(output).to include('--quiet')
      end
    end
  end

  describe '#build' do
    let(:build_command) { instance_double(XCFrameworkCLI::CLI::Commands::Build) }

    before do
      allow(XCFrameworkCLI::CLI::Commands::Build).to receive(:start)
    end

    it 'delegates to Build command' do
      # Stub ARGV to avoid issues
      stub_const('ARGV', ['build', '--project', 'Test.xcodeproj'])

      runner.invoke(:build)

      expect(XCFrameworkCLI::CLI::Commands::Build).to have_received(:start)
    end

    context 'when build raises an error' do
      let(:error) do
        XCFrameworkCLI::BuildError.new(
          'Build failed',
          suggestions: ['Check project path']
        )
      end

      before do
        allow(XCFrameworkCLI::CLI::Commands::Build).to receive(:start).and_raise(error)
        stub_const('ARGV', ['build'])
      end

      it 'handles the error gracefully' do
        expect { runner.invoke(:build) }.to raise_error(SystemExit)

        expect(XCFrameworkCLI::Utils::Logger).to have_received(:error).with('Build failed')
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:info).with('Suggestions:')
        expect(XCFrameworkCLI::Utils::Logger).to have_received(:info).with('  • Check project path')
      end
    end

    context 'when unexpected error occurs' do
      let(:error) { StandardError.new('Unexpected error') }

      before do
        allow(XCFrameworkCLI::CLI::Commands::Build).to receive(:start).and_raise(error)
        stub_const('ARGV', ['build'])
      end

      it 'handles the error gracefully' do
        expect { runner.invoke(:build) }.to raise_error(SystemExit)

        expect(XCFrameworkCLI::Utils::Logger).to have_received(:error).with('Unexpected error: Unexpected error')
      end
    end
  end

  describe 'default task' do
    it 'is help' do
      expect(described_class.default_task).to eq('help')
    end
  end

  describe 'version aliases' do
    it 'maps -v to version' do
      expect(described_class.map['-v']).to eq(:version)
    end

    it 'maps --version to version' do
      expect(described_class.map['--version']).to eq(:version)
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
