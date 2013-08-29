steroid_aggregations
====================
[![Build Status](https://travis-ci.org/romeuhcf/steroid_aggregations.png)](https://travis-ci.org/romeuhcf/steroid_aggregations)

ActiveRecord aggregation cache fields on steroids



## Example 

'''ruby
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
end
'''
