require 'spec_helper'
require 'db_helper'
describe 'max cache' do
  before(:each) do
    setup_db
    @bank = Bank.create!
    ActiveRecord::Base.logger = $l
  end

  after(:each) do
    teardown_db
  end


    describe 'on insert' do
      it 'should update' do
        @bank.accounts.create!(:balance => 10.0)
        @bank.accounts.create!(:balance => 30.1)
        @bank.accounts.create!(:balance => 20.0)
        @bank.accounts.create!(:balance => 30.0)
        @bank.accounts.create!(:balance => 10.0)
        @bank.reload.accounts_balance_max.should == 30.1
      end
    end
    describe 'on update' do
      it 'should update when new maximum is last update' do
        first = @bank.accounts.create!(:balance => 10.0)
        @bank.accounts.create!(:balance => 30.1)
        @bank.accounts.create!(:balance => 20.0)
        first.balance = 80.7; first.save!
        @bank.reload.accounts_balance_max.should == 80.7
      end
      it 'should update down when maximum is not the last anymore' do
        first = @bank.accounts.create!(:balance => 10.0)
        @bank.accounts.create!(:balance => 30.1)
        @bank.accounts.create!(:balance => 20.0)
        first.balance = 80.7; first.save!
        first.balance = 10.7; first.save!
        @bank.reload.accounts_balance_max.should == 30.1
      end
    end
    describe 'on delete' do
      it 'should update when maximum is destroyed' do
        @bank.accounts.create!(:balance => 10.0)
        @bank.reload.accounts_balance_max.should == 10.0
        m = @bank.accounts.create!(:balance => 30.1)
        @bank.reload.accounts_balance_max.should == 30.1
        @bank.accounts.create!(:balance => 18.0)
        @bank.reload.accounts_balance_max.should == 30.1
        m.destroy
        @bank.reload.accounts_balance_max.should == 18.0
      end

      it 'should not update when maximum is not destroyed' do
        @bank.accounts.create!(:balance => 10.0)
        @bank.accounts.create!(:balance => 30.1)
        o = @bank.accounts.create!(:balance => 18.0)
        @bank.reload.accounts_balance_max.should == 30.1
        o.destroy
        @bank.reload.accounts_balance_max.should == 30.1
      end

    end
    describe 'when empty' do
      it 'should be null' do
        @bank.reload.accounts_balance_min.should be_nil
      end
    end
    describe 'when reset after delete all children' do
      it 'should be null' do
        @bank.accounts.create!(:balance => 30.0)
        @bank.accounts.create!(:balance => 60.6)
        Account.delete_all


        @bank.reset_aggregations!
        @bank.reload.accounts_balance_max.should be_nil
      end
    end

  end


