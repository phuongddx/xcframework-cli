# frozen_string_literal: true

require 'spec_helper'
require 'xcframework_cli/utils/template'
require 'tmpdir'

RSpec.describe XCFrameworkCLI::Utils::Template do
  let(:template_name) { 'framework.info.plist' }
  let(:template) { described_class.new(template_name) }

  describe '#initialize' do
    it 'finds template in config/templates directory' do
      expect(template.template_name).to eq(template_name)
      expect(template.template_path).to include('config/templates')
      expect(template.template_path).to end_with(template_name)
    end

    it 'raises error for non-existent template' do
      expect do
        described_class.new('nonexistent.template')
      end.to raise_error(XCFrameworkCLI::Error, /Template not found/)
    end
  end

  describe '#render' do
    it 'renders template with variables' do
      content = template.render(
        {
          MODULE_NAME: 'TestFramework',
          PLATFORM: 'iPhoneOS',
          MIN_OS_VERSION: '15.0'
        }
      )

      expect(content).to include('<string>TestFramework</string>')
      expect(content).to include('<string>iPhoneOS</string>')
      expect(content).to include('<string>15.0</string>')
      expect(content).not_to include('{{MODULE_NAME}}')
      expect(content).not_to include('{{PLATFORM}}')
    end

    it 'saves rendered content to file' do
      Dir.mktmpdir do |tmpdir|
        output_path = File.join(tmpdir, 'output.plist')

        template.render(
          { MODULE_NAME: 'MyFramework', PLATFORM: 'iPhoneOS', MIN_OS_VERSION: '14.0' },
          save_to: output_path
        )

        expect(File.exist?(output_path)).to be true
        content = File.read(output_path)
        expect(content).to include('MyFramework')
      end
    end

    it 'returns rendered content when saving' do
      Dir.mktmpdir do |tmpdir|
        output_path = File.join(tmpdir, 'output.plist')

        content = template.render(
          { MODULE_NAME: 'TestFramework', PLATFORM: 'iPhoneOS', MIN_OS_VERSION: '15.0' },
          save_to: output_path
        )

        expect(content).to be_a(String)
        expect(content).to include('TestFramework')
      end
    end
  end

  describe '.render' do
    it 'renders template without creating instance' do
      content = described_class.render(
        'framework.modulemap',
        { MODULE_NAME: 'MyModule' }
      )

      expect(content).to include('framework module MyModule')
      expect(content).to include('umbrella header "MyModule-umbrella.h"')
      expect(content).not_to include('{{MODULE_NAME}}')
    end

    it 'saves rendered content with class method' do
      Dir.mktmpdir do |tmpdir|
        output_path = File.join(tmpdir, 'module.modulemap')

        described_class.render(
          'framework.modulemap',
          { MODULE_NAME: 'TestModule' },
          save_to: output_path
        )

        expect(File.exist?(output_path)).to be true
        content = File.read(output_path)
        expect(content).to include('TestModule')
      end
    end
  end

  describe 'template files' do
    it 'framework.info.plist template exists' do
      expect(File.exist?(template.template_path)).to be true
    end

    it 'framework.modulemap template exists' do
      modulemap_template = described_class.new('framework.modulemap')
      expect(File.exist?(modulemap_template.template_path)).to be true
    end
  end
end
