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

      context 'when interactive_ignore option is enabled' do
        let(:repo) { Pronto::Git::Repository.new('.') }
        let(:patches) { repo.diff('HEAD~1') }
        let(:config_hash) { { 'brakeman' => { 'interactive_ignore' => true } } }

        it "runs in interactive mode" do
          expect(::Brakeman).to receive(:run).with(hash_including(interactive_ignore: true)).and_call_original

          subject
        end
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

      context 'with a change to an erb file' do
        context 'with brakeman not included in pronto config' do
          let(:config_hash) { { 'foo' => {} } }
          include_context 'test repo'
          let(:patches) { repo.diff('b09de21aa02cbb43386e3a1d7e7e0a628df7ca66') }

          it 'should disable all checks' do
            expect(brakeman.run_all_checks?).to eq nil
          end

          its(:count) { should == 0 }
        end

        context 'with brakeman included in pronto config' do
          context 'with run all checks disabled' do
            let(:config_hash) { { 'brakeman' => { 'run_all_checks' => false } } }
            include_context 'test repo'
            let(:patches) { repo.diff('b09de21aa02cbb43386e3a1d7e7e0a628df7ca66') }

            it 'should disable all checks' do
              expect(brakeman.run_all_checks?).to eq false
            end

            its(:count) { should == 0 }
          end

          context 'with run all checks enabled' do
            let(:config_hash) { { 'brakeman' => { 'run_all_checks' => true } } }
            include_context 'test repo'
            let(:patches) { repo.diff('b09de21aa02cbb43386e3a1d7e7e0a628df7ca66') }

            it 'should enable all checks' do
              expect(brakeman.run_all_checks?).to eq true
            end
            its(:count) { should == 1 }
            it "should report a tabnabbing vulnerability" do
              expect(subject.first.msg).to include("Possible security vulnerability: [When opening a link in a new tab without setting `rel:")
            end
          end
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
