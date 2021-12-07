require 'spec_helper'

module Pronto
  describe Brakeman do
    let(:brakeman) { Brakeman.new(patches) }
    let(:pronto_config) do
      instance_double Pronto::ConfigFile, to_h: config_hash
    end
    let(:config_hash) { {} }

    before do
      allow(Pronto::ConfigFile).to receive(:new) { pronto_config }
    end

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

      context 'with run all checks disabled' do
        let(:config_hash) { { 'brakeman' => { 'run_all_checks' => false } } }
        include_context 'test repo'
        let(:patches) { repo.diff('7835d50de98efc04d757faeb74892438c592f30c') }

        its(:count) { should == 1 }
      end

      context 'with run all checks enabled' do
        let(:config_hash) { { 'brakeman' => { 'run_all_checks' => true } } }
        include_context 'test repo'
        let(:patches) { repo.diff('7835d50de98efc04d757faeb74892438c592f30c') }

        its(:count) { should == 2 }
      end
    end

    describe "#severity_for_confidence" do
      subject { brakeman.severity_for_confidence(confidence_level) }

      let(:patches) { nil }

      context "when confidence is HIGH" do
        let(:confidence_level) { 0 }

        it { should == :fatal }
      end

      context "when confidence is MEDIUM" do
        let(:confidence_level) { 1 }

        it { should == :warning }
      end

      context "when confidence is anything else" do
        let(:confidence_level) { 2 }

        it { should == :info }
      end
    end
  end
end
