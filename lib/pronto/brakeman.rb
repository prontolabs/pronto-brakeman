require 'pronto'
require 'brakeman'

module Pronto
  class Brakeman < Runner
    def run
      files = ruby_patches.map do |patch|
        patch.new_file_full_path.relative_path_from(repo_path).to_s
      end

      return [] unless files.any?

      output = ::Brakeman.run(app_path: repo_path,
                              output_formats: [:to_s],
                              only_files: files)
      messages_for(ruby_patches, output).compact
    rescue ::Brakeman::NoApplication
      []
    end

    def messages_for(ruby_patches, output)
      output.filtered_warnings.map do |warning|
        patch = patch_for_warning(ruby_patches, warning)

        next unless patch
        line = patch.added_lines.find do |added_line|
          added_line.new_lineno == warning.line
        end

        new_message(line, warning) if line
      end
    end

    def new_message(line, warning)
      Message.new(line.patch.delta.new_file[:path], line,
                  severity_for_confidence(warning.confidence),
                  "Possible security vulnerability: [#{warning.message}](#{warning.link})",
                  nil, self.class)
    end

    def severity_for_confidence(confidence_level)
      case confidence_level
      when 0 # Brakeman High confidence
        :fatal
      when 1 # Brakeman Medium confidence
        :warning
      else # Brakeman Low confidence (and other possibilities)
        :info
      end
    end

    def patch_for_warning(ruby_patches, warning)
      ruby_patches.find do |patch|
        patch.new_file_full_path.to_s == warning.file.absolute
      end
    end
  end
end
