require 'pronto'
require 'brakeman'

module Pronto
  class Brakeman < Runner
    def run(patches, _)
      return [] unless patches

      ruby_patches = patches.select { |patch| patch.additions > 0 }
        .select { |patch| ruby_file?(patch.new_file_full_path) }

      files = ruby_patches.map { |patch| patch.new_file_full_path.to_s }

      if files.any?
        output = ::Brakeman.run(app_path: ruby_patches.first.repo.path,
                                output_formats: [:to_s],
                                only_files: files)
        messages_for(ruby_patches, output).compact
      else
        []
      end
    end

    def messages_for(ruby_patches, output)
      output.checks.all_warnings.map do |warning|
        patch = patch_for_warning(ruby_patches, warning)

        if patch
          line = patch.added_lines.find do |added_line|
            added_line.new_lineno == warning.line
          end

          new_message(line, warning) if line
        end
      end
    end

    def new_message(line, warning)
      Message.new(line.patch.delta.new_file[:path], line, :warning,
                  "Possible security vulnerability: #{warning.message}")
    end

    def patch_for_warning(ruby_patches, warning)
      ruby_patches.find do |patch|
        patch.new_file_full_path.to_s == warning.file
      end
    end
  end
end
