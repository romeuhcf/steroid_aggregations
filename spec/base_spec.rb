require 'spec_helper'
require 'db_helper'

describe 'aggregation cache' do
  before(:each) do
    setup_db
    @bank = Bank.create!
  end

  after(:each) do
    teardown_db
  end

  describe 'skip aggregation' do
  end
  describe 'reset aggregations' do
    it 'should reset aggregations' do
      @bank.reload.accounts_count.should == 0
      10.times {  @bank.accounts.create! }
      @bank.reload.accounts_count.should == 10

      Account.destroy_all
      @bank.reload.accounts_count.should == 0

      10.times {  @bank.accounts.create! }
      @bank.reload.accounts_count.should == 10
      Account.delete_all
      @bank.reload.accounts_count.should == 10

      @bank.reset_aggregations!
    end
  end
end
