# frozen_string_literal: true

require 'English'

# Takes the public repository for the Wikibase export and tests to see if there are any changes.
# If the repository does not exist in the app, the program will clone before executing.
class WikibaseIngest
  class CloneFailed < StandardError; end
  class PullFailed < StandardError; end

  attr_reader :path, :repository, :json_file_path

  # @param [String] path The relative path to the local instance of the repository relative to the app root directory.
  # @param [String] repository The public Git repository for the exported data.
  # @param [String] json_file The relative path to the exported json file relative to the repository root directory.
  def initialize(path: self.class.repository_path, repository: self.class.repository_url,
                 json_file: self.class.json_file_path)
    @path = path
    @repository = repository
    @json_file_path = json_file
  end

  # Gets the full path to the json export file
  # @return [String]
  def json_file_full_path
    File.expand_path(json_file_path, path).to_s
  end

  # Ingest the new changes to the export file
  # @return [Boolean, WikibaseExportVersion] Returns false if there are not changes and the WikibaseExportVersion
  #   if the export file changed
  # @raise [CloneFailed] if cloning the repository failed
  # @raise [PullFailed] if unable to pull the latest changes
  # @raise [ActiveRecord::ActiveRecordError] if something went wrong when creating the database entry
  def execute!
    clone_repository! unless repository_exists?
    pull_repository!
    return false if WikibaseExportVersion.version_exists? json_file_full_path

    WikibaseExportVersion.create_by_file! json_file_full_path
  end

  private

  # Check if the repository exists
  def repository_exists?
    Dir.exist? path
  end

  # Clone the repository
  def clone_repository!
    execute_command('git', 'clone', repository,
                    path) || raise(CloneFailed, "Unable to clone '#{repository}' repository")
  end

  # Pull the latest changes in the repository
  def pull_repository!
    execute_command('git', 'pull', '--ff-only', dir: path) || raise(PullFailed, 'Unable to get the latest changes')
  end

  # Run the command
  def execute_command(*command)
    args = command.extract_options!
    output = safe_execute_command command, **args
    status = $CHILD_STATUS&.exitstatus
    Rails.logger.info "[WikibaseIngest] run '#{command.join ' '}' {exit: #{status}}"
    Rails.logger.debug output.join "\n" if output.present?
    $CHILD_STATUS&.success?
  end

  # Safely run the command
  def safe_execute_command(command, options = {})
    IO.popen(command, err: :out, chdir: options.fetch(:dir, Rails.root)) { |io| io.readlines.compact }
  rescue StandardError
    nil
  end

  class << self
    def repository_path
      Rails.root.join(ENV.fetch('WIKIBASE_REPOSITORY_PATH', '../ds_exports')).to_s
    end

    def repository_url
      ENV.fetch('WIKIBASE_REPOSITORY_URL', 'https://github.com/DigitalScriptorium/ds-exports')
    end

    def json_file_path
      ENV.fetch('WIKIBASE_EXPORT_JSON_FILE', 'json/ds-latest.json.gz')
    end

    def json_file_full_path
      File.expand_path(json_file_path, repository_path).to_s
    end
  end
end
