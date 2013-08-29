require 'spec_helper'
require 'db_helper'
describe 'avarage cache' do
  before(:each) do
    setup_db
    @bank = Bank.create!
  end

  after(:each) do
    teardown_db
  end

  describe 'on insert' do
    it 'should update' do
      @bank.accounts.create!(:balance => 10.0)
      @bank.accounts.create!(:balance => 20.0)
      @bank.accounts.create!(:balance => 30.0)
      @bank.reload.accounts_balance_avg.should == 20.0
    end
  end
  describe 'on update' do
    it 'should update' do
      @bank.accounts.create!(:balance => 10.0)
      @bank.reload.accounts_balance_avg.should == 10.0
      @bank.accounts.create!(:balance => 20.0)
      @bank.reload.accounts_balance_avg.should == 15.0
      last = @bank.accounts.create!(:balance => 30.0)
      last.balance= 60.3;last.save!
      @bank.reload.accounts_balance_avg.should == 30.1
    end
  end
  describe 'on delete' do
    it 'should update' do
      first = @bank.accounts.create!(:balance => 90.0)
      @bank.accounts.create!(:balance => 30.0)
      @bank.accounts.create!(:balance => 60.6)
      @bank.reload.accounts_balance_avg.should == 60.2
      first.destroy
      @bank.reload.accounts_balance_avg.should == 45.3
    end 
  end
  describe 'when empty' do
    it 'should be null' do
      @bank.reload.accounts_balance_avg.should be_nil
    end
  end
  describe 'when reset after delete all children' do
    it 'should be null' do
      @bank.accounts.create!(:balance => 30.0)
      @bank.accounts.create!(:balance => 60.6)
      @bank.accounts.delete_all
      @bank.reset_aggregations!
      @bank.reload.accounts_balance_avg.should be_nil
    end
  end
end


