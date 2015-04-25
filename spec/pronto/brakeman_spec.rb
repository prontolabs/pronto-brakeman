require 'spec_helper'

module Pronto
  describe Brakeman do
    let(:brakeman) { Brakeman.new }

    describe '#run' do
      subject { brakeman.run(patches, nil) }

      context 'patches are nil' do
        let(:patches) { nil }
        it { should == [] }
      end

      context 'no patches' do
        let(:patches) { [] }
        it { should == [] }
      end

      context 'patches with a single unsafe redirect' do
        let(:repo) { Git::Repository.new('spec/fixtures/test.git') }
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
