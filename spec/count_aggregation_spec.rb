require 'spec_helper'
require 'db_helper'
describe 'count cache' do
  before(:each) do
    setup_db
    @bank = Bank.create!
    ActiveRecord::Base.logger = $l
  end

  after(:each) do
    teardown_db
  end


  describe 'on insert' do
    it 'should start on zero' do
      @bank.reload.accounts_count.should == 0
    end
    it 'should be here' do
      @bank.reload.accounts_count.should == 0
      @bank.accounts.create!
      @bank.reload.accounts_count.should == 1
      @bank.accounts.create!
      @bank.reload.accounts_count.should == 2
      @bank.accounts.create!
      @bank.reload.accounts_count.should == 3
      @bank.accounts.create!
      @bank.reload.accounts_count.should == 4
      @bank.accounts.create!
      @bank.accounts.create!
      SteroidAggregations::Aggregations::Count.any_instance.should_receive(:aggregate_on).and_call_original
      @bank.accounts.create!
      @bank.reload.accounts_count.should == 7
    end
  end
  describe 'on update' do
    it 'should check if should change' do
      @bank.reload.accounts_count.should == 0
      account = @bank.accounts.create!
      @bank.reload.accounts_count.should == 1
      SteroidAggregations::Aggregations::Count.any_instance.should_receive(:aggregate_on).and_call_original
      account.balance = 10; account.save!
      @bank.reload.accounts_count.should == 1
    end
    it 'should not change counter' do
      @bank.reload.accounts_count.should == 0
      account = @bank.accounts.create!
      @bank.reload.accounts_count.should == 1
      account.balance = 10; account.save!
      @bank.reload.accounts_count.should == 1
      account.balance = 100; account.save!
      @bank.reload.accounts_count.should == 1
    end
  end
  describe 'on delete' do
    it 'should start on zero' do
      @bank.reload.accounts_count.should == 0
      account = @bank.accounts.create!
      @bank.reload.accounts_count.should == 1
      Account.destroy_all
      @bank.reload.accounts_count.should == 0
    end
  end
  describe 'when empty' do
    it 'should be zero' do
      @bank.reload.accounts_count.should == 0
    end
  end
  describe 'when reset after delete all children' do
    it 'should be zero' do
      @bank.accounts.create!(:balance => 30.0)
      @bank.accounts.create!(:balance => 60.6)
      @bank.accounts.delete_all
      @bank.reset_aggregations!
      @bank.reload.accounts_count.should == 0
    end
  end

end

