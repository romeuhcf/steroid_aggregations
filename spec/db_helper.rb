require 'active_record'
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  $realstdout = $stdout
  $stdout = File.open('/dev/null', 'w')
  ActiveRecord::Schema.define(:version => 1) do
    create_table :banks do |t|
      t.string :name
      t.integer :accounts_count
      t.decimal :accounts_balance_avg, :scale => 1, :precision => 6
      t.decimal :accounts_balance_min, :scale => 1, :precision => 6
      t.decimal :accounts_balance_max, :scale => 1, :precision => 6
      t.decimal :accounts_balance_sum, :scale => 1, :precision => 6
      t.integer :accounts_audited_count
    end
    
    create_table :accounts do |t|
      t.integer :bank_id
      t.decimal :balance
      t.datetime :last_audited_at , null:true
    end
  end
  $stdout = $realstdout
end

def teardown_db
  $realstdout = $stdout
  $stdout = File.open('/dev/null', 'w')
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
  $stdout = $realstdout
end

class Account < ActiveRecord::Base
  belongs_to :bank
end

class Bank < ActiveRecord::Base
  has_many :accounts
  aggregate_cache :accounts, :count, :on => :accounts_count 
  aggregate_cache :accounts, :avg, :field => :balance, :on => :accounts_balance_avg
  aggregate_cache :accounts, :min, :field => :balance, :on => :accounts_balance_min
  aggregate_cache :accounts, :max, :field => :balance
  aggregate_cache :accounts, :sum, :field => :balance
  aggregate_cache :accounts, :count, :on => :accounts_audited_count, :guard => :last_audited_at


end
