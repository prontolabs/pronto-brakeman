require 'rspec'
require 'rspec/its'
require 'pronto/brakeman'
require 'fileutils'

RSpec.shared_context 'test repo' do
  let(:git) { 'spec/fixtures/test.git/git' }
  let(:dot_git) { 'spec/fixtures/test.git/.git' }

  before { FileUtils.mv(git, dot_git) }
  let(:repo) { Pronto::Git::Repository.new('spec/fixtures/test.git') }
  after { FileUtils.mv(dot_git, git) }
end

RSpec.shared_context 'brakeman runs all checks' do
  let(:brakeman_config) { repo.path.join('config', 'brakeman.yml') }
  before { FileUtils.cp('spec/fixtures/files/brakeman-run-all-checks.yml', brakeman_config) }
  after { FileUtils.rm(brakeman_config) }
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
  config.mock_with(:rspec) { |c| c.syntax = :should }
end
