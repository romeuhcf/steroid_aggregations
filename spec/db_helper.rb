require 'active_record'
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")


def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :banks do |t|
      t.string :name
      t.integer :accounts_count
      t.float :accounts_balance_avg
      t.float :accounts_balance_min
      t.float :accounts_balance_max
      t.float :accounts_balance_sum
    end
    
    create_table :accounts do |t|
      t.integer :bank_id
      t.float :balance
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Bank < ActiveRecord::Base
  has_many :accounts
  aggregate_cache :accounts, :count, :on => :accounts_count 
  aggregate_cache :accounts, :avg, :field => :balance, :on => :accounts_balance_avg
  aggregate_cache :accounts, :min, :field => :balance, :on => :accounts_balance_min
  aggregate_cache :accounts, :max, :field => :balance
  aggregate_cache :accounts, :sum, :field => :balance
end

class Account < ActiveRecord::Base
  belongs_to :bank
end
