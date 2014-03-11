require "steroid_aggregations/version"
require "steroid_aggregations/aggregations/count"
require "steroid_aggregations/aggregations/sum"
require "steroid_aggregations/aggregations/avg"
require "steroid_aggregations/aggregations/min"
require "steroid_aggregations/aggregations/max"
require "active_record"


# XXX  se tiver avg, pode usar um counter e um sum, ou, ao menos um counter, mas tem q dar prio para counter, sum
module SteroidAggregations
  module Aggregations
    def self.factory(parent_klass, aggr_func, assoc_name, relation, options = {})
      
      klass_name = "::SteroidAggregations::Aggregations::#{aggr_func.to_s.camelize}"
      klass = begin 
        klass_name.constantize
      rescue 
        raise ArgumentError, "No such aggregation function '#{aggr_func}'. Expected implementation of '#{klass_name}'!"
      end

      klass.new(parent_klass, assoc_name, relation, options)
      
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def aggregate_cache(assoc_name, aggr_func, options ={})
      relation = options[:relation] || self.name.underscore.gsub('/', '_')





      has_many_association = reflect_on_association(assoc_name.to_sym)
      raise ArgumentError, "'#{self.name}' has no association called '#{association}'" unless has_many_association

      if has_many_association.is_a? ActiveRecord::Reflection::ThroughReflection
        has_many_association = has_many_association.through_reflection
      end

      acts_as_steroid_aggregator
      aggregator = Aggregations.factory(self, aggr_func, assoc_name, relation, options)
      
      child_class  = has_many_association.klass


      raise "Please define relation option to aggregate cache. #{child_class} doesn't have a #{relation} method!" unless child_class.instance_methods.include?(relation.to_sym)
      child_class.acts_as_steroid_aggregatable(aggregator)
      self.steroid_aggregations << aggregator
    end

 
    def acts_as_steroid_aggregatable(aggregator)
      after_create {|record| aggregator.aggregate_on(:create, record)}
      after_destroy {|record| aggregator.aggregate_on(:destroy, record)}
      after_update {|record| aggregator.aggregate_on(:update, record)}
    end

    def acts_as_steroid_aggregator
      return if self.respond_to? :steroid_aggregations

      self.class_eval do
        cattr_accessor :steroid_aggregations
      end
      self.steroid_aggregations = []
      after_create :reset_aggregations!
      self.send :include, SteroidAggregations::InstanceMethods
    end
  end
  module InstanceMethods
    def postpone_aggregations
      @__skip_steroid_aggregations = true
      Rails.logger.debug("#{self} Postponing steroid aggregations")
      yield if block_given?
      Rails.logger.debug("#{self} Recalculating postponed steroid aggregations")
      @__skip_steroid_aggregations = false
      self.reset_aggregations!
    end

    def __skip_steroid_aggregations?
      @__skip_steroid_aggregations && true
    end

    def reset_aggregations!
      self.reload.class.steroid_aggregations.each do |aggregation|
        aggregation.reset_cache!(self)
      end
    end
  end
end
ActiveRecord::Base.send :include , SteroidAggregations
