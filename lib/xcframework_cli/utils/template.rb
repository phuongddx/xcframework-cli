# frozen_string_literal: true

module XCFrameworkCLI
  module Utils
    # Template renderer for framework files
    # Handles variable substitution in template files
    class Template
      attr_reader :template_name, :template_path

      # Initialize template
      #
      # @param template_name [String] Name of template file
      def initialize(template_name)
        @template_name = template_name
        @template_path = find_template_path
        validate_template!
      end

      # Render template with variables
      #
      # @param variables [Hash] Variables for substitution (e.g., { MODULE_NAME: 'MyFramework' })
      # @param save_to [String, nil] Optional path to save rendered output
      # @return [String] Rendered template content
      def render(variables, save_to: nil)
        content = File.read(template_path)

        # Replace all {{VARIABLE}} placeholders
        variables.each do |key, value|
          placeholder = "{{#{key}}}"
          content = content.gsub(placeholder, value.to_s)
        end

        if save_to
          File.write(save_to, content)
          Utils::Logger.debug("Rendered template #{template_name} to #{save_to}")
        end

        content
      end

      private

      # Find template file path
      #
      # @return [String] Absolute path to template
      def find_template_path
        # Check in config/templates directory
        templates_dir = File.expand_path('../../../../config/templates', __FILE__)
        template_file = File.join(templates_dir, template_name)

        return template_file if File.exist?(template_file)

        # Check relative to current directory
        relative_path = File.join('config', 'templates', template_name)
        return relative_path if File.exist?(relative_path)

        # Return default path even if not found (will be validated)
        template_file
      end

      # Validate template exists
      #
      # @raise [Error] if template not found
      def validate_template!
        return if File.exist?(template_path)

        raise Error, "Template not found: #{template_name} (searched: #{template_path})"
      end

      class << self
        # Render template directly without creating instance
        #
        # @param template_name [String] Template name
        # @param variables [Hash] Variables for substitution
        # @param save_to [String, nil] Optional save path
        # @return [String] Rendered content
        def render(template_name, variables, save_to: nil)
          new(template_name).render(variables, save_to: save_to)
        end
      end
    end
  end
end
