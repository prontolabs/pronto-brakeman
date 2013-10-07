require 'pronto'
require 'brakeman'

module Pronto
  class Brakeman < Runner
    def run(patches)
      return [] unless patches

      ruby_patches = patches.select { |patch| patch.additions > 0 }
                            .select { |patch| ruby_file?(patch.new_file_full_path) }

      files = ruby_patches.map { |patch| patch.new_file_full_path.to_s }

      if files.any?
        output = ::Brakeman.run(app_path: '.',
                                output_formats: [:to_s],
                                only_files: files)
        messages_for(ruby_patches, output)
      else
        []
      end
    end

    def messages_for(ruby_patches, output)
      # output.errors
      result = []

      output.checks.all_warnings.each do |warning|
        patch = patch_for_warning(ruby_patches, warning)

        line = patch.added_lines.select do |added_line|
          added_line.new_lineno == warning.line
        end.first

        result << new_warning_message(line, warning) if line
      end

      result
    end

    def new_warning_message(line, warning)
      Message.new(line.patch.delta.new_file[:path], line,
                  :warning, 'Security vulnerability: ' + warning.message)
    end

    def patch_for_warning(ruby_patches, warning)
      ruby_patches.select do |patch|
        patch.new_file_full_path.to_s == warning.file
      end.first
    end
  end
end
