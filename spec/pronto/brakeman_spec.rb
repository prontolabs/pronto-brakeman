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
            'Possible security vulnerability: Possible unprotected redirect'
        end
      end
    end
  end
end
