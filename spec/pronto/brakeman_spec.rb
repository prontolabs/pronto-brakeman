require 'spec_helper'

module Pronto
  describe Brakeman do
    let(:brakeman) { Brakeman.new(patches) }

    describe '#run' do
      subject { brakeman.run }

      context 'patches are nil' do
        let(:patches) { nil }
        it { should == [] }
      end

      context 'no patches' do
        let(:patches) { [] }
        it { should == [] }
      end

      context 'not a rails app' do
        let(:repo) { Pronto::Git::Repository.new('.') }
        let(:patches) { repo.diff('HEAD~1') }
        it { should == [] }
      end

      context 'patches with a single unsafe redirect' do
        include_context 'test repo'
        let(:patches) { repo.diff('da70127') }

        its(:count) { should == 1 }
        its(:'first.msg') do
          should ==
            'Possible security vulnerability: [Possible unprotected redirect](https://brakemanscanner.org/docs/warning_types/redirect/)'
        end
      end

      context 'patches with an unscoped find' do
        include_context 'test repo'
        include_context 'brakeman runs all checks'
        let(:patches) { repo.diff('369f92e^') }

        its(:count) { should == 0 }
      end

      context 'patches with an unscoped find and scans all files' do
        include_context 'test repo'
        include_context 'brakeman runs all checks'
        before(:context) do
          @original_env = ENV.to_hash
          ENV['PRONTO_BRAKEMAN_ONLY_FILES'] = '0'
        end
        after(:context) { ENV.replace @original_env }
        let(:patches) { repo.diff('369f92e^') }

        its(:count) { should == 1 }
        its(:'first.msg') do
          should =~
            /^Possible security vulnerability: \[Unscoped call to /
        end
      end
    end

    describe '#severity_for_confidence' do
      subject { brakeman.severity_for_confidence(confidence_level) }

      let(:patches) { nil }

      context 'when confidence is HIGH' do
        let(:confidence_level) { 0 }

        it { should == :fatal }
      end

      context 'when confidence is MEDIUM' do
        let(:confidence_level) { 1 }

        it { should == :warning }
      end

      context 'when confidence is anything else' do
        let(:confidence_level) { 2 }

        it { should == :info }
      end
    end
  end
end
