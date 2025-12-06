# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/xcodebuild/result'

RSpec.describe XCFrameworkCLI::Xcodebuild::Result do
  describe '#initialize' do
    it 'creates a successful result' do
      result = described_class.new(success: true, stdout: 'output', exit_code: 0)
      expect(result.success?).to be true
      expect(result.stdout).to eq('output')
      expect(result.exit_code).to eq(0)
    end

    it 'creates a failed result' do
      result = described_class.new(success: false, stderr: 'error', exit_code: 1)
      expect(result.failure?).to be true
      expect(result.stderr).to eq('error')
      expect(result.exit_code).to eq(1)
    end

    it 'sets default values' do
      result = described_class.new(success: true)
      expect(result.stdout).to eq('')
      expect(result.stderr).to eq('')
      expect(result.exit_code).to eq(0)
      expect(result.command).to eq('')
    end
  end

  describe '#success?' do
    it 'returns true for successful result' do
      result = described_class.new(success: true)
      expect(result.success?).to be true
    end

    it 'returns false for failed result' do
      result = described_class.new(success: false)
      expect(result.success?).to be false
    end
  end

  describe '#failure?' do
    it 'returns false for successful result' do
      result = described_class.new(success: true)
      expect(result.failure?).to be false
    end

    it 'returns true for failed result' do
      result = described_class.new(success: false)
      expect(result.failure?).to be true
    end
  end

  describe '#output' do
    it 'returns stdout when stderr is empty' do
      result = described_class.new(success: true, stdout: 'output')
      expect(result.output).to eq('output')
    end

    it 'returns stderr when stdout is empty' do
      result = described_class.new(success: false, stderr: 'error')
      expect(result.output).to eq('error')
    end

    it 'combines stdout and stderr' do
      result = described_class.new(success: true, stdout: 'output', stderr: 'warning')
      expect(result.output).to eq("output\nwarning")
    end

    it 'returns empty string when both are empty' do
      result = described_class.new(success: true)
      expect(result.output).to eq('')
    end
  end

  describe '#error_message' do
    it 'returns nil for successful result' do
      result = described_class.new(success: true, stderr: 'not an error')
      expect(result.error_message).to be_nil
    end

    it 'returns stderr for failed result' do
      result = described_class.new(success: false, stderr: 'error message')
      expect(result.error_message).to eq('error message')
    end

    it 'returns stdout when stderr is empty' do
      result = described_class.new(success: false, stdout: 'error in stdout')
      expect(result.error_message).to eq('error in stdout')
    end
  end

  describe '#to_s' do
    it 'shows SUCCESS for successful result' do
      result = described_class.new(success: true, exit_code: 0)
      expect(result.to_s).to eq('SUCCESS (exit: 0)')
    end

    it 'shows FAILURE for failed result' do
      result = described_class.new(success: false, exit_code: 1)
      expect(result.to_s).to eq('FAILURE (exit: 1)')
    end
  end

  describe '#inspect' do
    it 'shows class name and key attributes' do
      result = described_class.new(success: true, exit_code: 0)
      expect(result.inspect).to include('Result')
      expect(result.inspect).to include('success=true')
      expect(result.inspect).to include('exit_code=0')
    end
  end
end
