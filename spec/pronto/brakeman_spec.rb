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
        let(:patches) { repo.diff('225af1a') }

        it 'should disable all checks' do
          expect(brakeman.run_all_checks?).to eq false
        end

        its(:count) { should == 0 }
      end

      context 'with run all checks enabled' do
        let(:config_hash) { { 'brakeman' => { 'run_all_checks' => true } } }
        include_context 'test repo'
        let(:patches) { repo.diff('225af1a') }

        it 'should enable all checks' do
          expect(brakeman.run_all_checks?).to eq true
        end
        its(:count) { should == 1 }
        its(:'last') do
          should ==
            'Possible security check check check: [/)'
        end
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
