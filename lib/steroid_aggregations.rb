require "steroid_aggregations/version"
require "active_record"

module SteroidAggregations

  module Aggregations

    def self.factory(aggr_func, assoc_name, options = {})
      klass_name = "::SteroidAggregations::Aggregations::#{aggr_func.to_s.camelize}"
      klass = begin 
        klass_name.constantize
      rescue 
        raise ArgumentError, "No such aggregation function '#{aggr_func}'. Expected implementation of '#{klass_name}'!"
      end
      klass.new(assoc_name, options)
      
    end

    class Base
      attr_reader :association_name
      attr_reader :options
      def cache_column
        @options[:on] || [association_name, @options[:field], self.class.name.split('::').last.downcase].join('_')
      end

      def initialize(assoc_name, options={})
        @association_name = assoc_name
        @options = options || {}
      end
    end

    class Count < Base
      def reset_cache!(cache_holder_instance)
        cache_holder_instance.update_attributes(cache_column => 0)
      end
    end

    class Sum < Count
    end 

    class Avg < Base
      def reset_cache!(cache_holder_instance)
      end
    end
    class Min < Base
      def reset_cache!(cache_holder_instance)
      end
    end
    class Max < Base
      def reset_cache!(cache_holder_instance)
      end
    end
  end

  def self.included(base)
    puts "#{base} includes #{self}"
    base.extend(ClassMethods)
  end

  module ClassMethods
    def aggregate_cache(assoc_name, aggr_func, options ={})
      acts_as_steroid_aggregator
      self.steroid_aggregations << Aggregations.factory(aggr_func, assoc_name, options)
    end

 
    def acts_as_steroid_aggregator
      return if self.respond_to? :steroid_aggregations

      self.class_eval do
        cattr_accessor :steroid_aggregations
      end
      self.steroid_aggregations = []
      after_create :_steroid_aggregation_reset
      self.send :include, SteroidAggregations::InstanceMethods
    end
  end
require 'pp'
  module InstanceMethods
    def _steroid_aggregation_reset
      self.class.steroid_aggregations.each do |aggregation|
        aggregation.reset_cache!(self)
      end
    end
  end


end
ActiveRecord::Base.send :include , SteroidAggregations
puts 'included'
