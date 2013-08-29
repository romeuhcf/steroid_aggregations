require 'spec_helper'
require 'db_helper'
describe 'sum cache' do
  before(:each) do
    setup_db
    @bank = Bank.create!
    ActiveRecord::Base.logger = $l
  end

  after(:each) do
    teardown_db
  end

  describe 'on insert' do
    it "should increase when more positive are added" do
      @bank.accounts.create!(:balance => 30.0)
      @bank.accounts.create!(:balance => 30.5)
      @bank.accounts.create!(:balance => 30.4)
      @bank.reload.accounts_balance_sum.should == 90.9
    end
    it "should not change when more zeroed are added" do
      @bank.accounts.create!(:balance => 30.0)
      @bank.accounts.create!(:balance => 30.5)
      @bank.accounts.create!(:balance => 0)
      @bank.accounts.create!(:balance => 0)
      @bank.reload.accounts_balance_sum.should == 60.5
    end

    it "should decrease when more negative are added" do
      @bank.accounts.create!(:balance => 30.0)
      @bank.accounts.create!(:balance => -1.1)
      @bank.accounts.create!(:balance => -1.1)
      @bank.reload.accounts_balance_sum.should == 27.8
    end
  end
  describe 'on update' do
    it "should decrease when updating to smaller positive number" do
      f = @bank.accounts.create!(:balance => 30.0)
      @bank.accounts.create!(:balance => 30.0)
      @bank.reload.accounts_balance_sum.should == 60
      f.balance = 20.5; f.save!
      @bank.reload.accounts_balance_sum.should == 50.5
    end
    it "should increase when updating to smaller negative number" do
      @bank.accounts.create!(:balance => 60.0)
      f = @bank.accounts.create!(:balance => -30.0)
      @bank.reload.accounts_balance_sum.should == 30
      f.balance = -20.5; f.save!
      @bank.reload.accounts_balance_sum.should == 39.5
    end
    it "should increase when updating to bigger positive number" do
      f = @bank.accounts.create!(:balance => 30.0)
      @bank.accounts.create!(:balance => 30.0)
      @bank.reload.accounts_balance_sum.should == 60
      f.balance = 40.5; f.save!
      @bank.reload.accounts_balance_sum.should == 70.5
    end
  end
  describe 'on delete' do
    it 'should be updated' do
      @bank.accounts.create!(:balance => 30.0)
      f = @bank.accounts.create!(:balance => 20.0)
      @bank.accounts.create!(:balance => 30.0)
      @bank.reload.accounts_balance_sum.should == 80
      f.destroy
      @bank.reload.accounts_balance_sum.should == 60
    end
  end
  describe 'when empty' do
    it 'should be zero' do
      @bank.reload.accounts_balance_sum.should == 0.0
    end
  end
  describe 'when reset after delete all children' do
    it 'should be zero' do
      @bank.accounts.create!(:balance => 30.0)
      @bank.accounts.create!(:balance => 60.6)
      @bank.reload.accounts_balance_sum.should == 90.6
      @bank.accounts.delete_all
      @bank.reset_aggregations!
      @bank.reload.accounts_balance_sum.should == 0.0
    end
  end
end


