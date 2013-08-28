require 'spec_helper'
require 'db_helper'


describe 'aggregation cache' do
  before(:each) do
    setup_db
  end

  after(:each) do
    teardown_db
  end

  describe 'count cache' do
    describe 'on insert' do
    end
    describe 'on update' do
    end
    describe 'on delete' do
    end
    describe 'when empty' do
      it 'should be zero' do
        bank = Bank.create!
        bank.accounts_count.should == 0
      end
    end
  end
  describe 'avarage cache' do
    describe 'on insert' do
    end
    describe 'on update' do
    end
    describe 'on delete' do
    end
    describe 'when empty' do
      it 'should be null' do
        bank = Bank.create!
        bank.accounts_balance_avg.should be_nil
      end
    end
  end

  describe 'sum cache' do
    describe 'on insert' do
    end
    describe 'on update' do
    end
    describe 'on delete' do
    end
    describe 'when empty' do
      it 'should be zero' do
        bank = Bank.create!
        bank.accounts_balance_sum.should == 0.0
      end
    end
  end

  describe 'min cache' do
    describe 'on insert' do
    end
    describe 'on update' do
    end
    describe 'on delete' do
    end
    describe 'when empty' do
      it 'should be null' do
        bank = Bank.create!
        bank.accounts_balance_min.should be_nil
      end
    end
  end


  describe 'max cache' do
    describe 'on insert' do
    end
    describe 'on update' do
    end
    describe 'on delete' do
    end
    describe 'when empty' do
      it 'should be null' do
        bank = Bank.create!
        bank.accounts_balance_min.should be_nil
      end
    end
  end
end

describe 'skip aggregation' do
end
