require "steroid_aggregations/version"
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

    class Base
      attr_reader :association_name
      attr_reader :options
      def aggregate_on(event, record)
        parent = parent_instance(record)
        if parent && parent.__skip_steroid_aggregations?
          Rails.logger.debug "Skipping steroid aggregations on #{record}##{event}|#{association_name}|#{options} for #{parent} "
        else
          my_aggregate_on(event, record) 
        end
      end

      def cache_column
        @options[:on] || [association_name, @options[:field], self.class.name.split('::').last.downcase].compact.join('_')
      end
     
      def child_aggregatable_field
        @options[:field]
      end

      def current_value(record)
        record.send(child_aggregatable_field).to_f
      end

      def parent_instance(record)
        record.send(@relation)
      end
 
      def parent_instance_reload(record)
        parent_instance(record).try :reload
      end
   
      def current_aggregation_value(record)
        parent_instance(record).send(cache_column).to_f
      end

      def new_value(record)
        current_value(record)
      end

      def aggregator_id(record)
        record.send("#{@relation}_id") 
      end

      def aggregation_replace(value, record)
        @parent_klass.where(:id => aggregator_id(record)).update_all(cache_column => value)
        parent_instance_reload(record)
      end

      def aggregation_patch(diff, record)
        return if diff == 0.0
        @parent_klass.update_counters(aggregator_id(record), {cache_column => diff})
        parent_instance_reload(record)
      end

      def old_value(record)
        record.send("#{child_aggregatable_field}_was").to_f
      end
 
      def siblings(record)
        parent_instance(record).send(@association_name)
      end

      def reset_cache!(parent_instance)
        new_value = recalculate(parent_instance) 
        current_value = parent_instance.send(cache_column)
        parent_instance.update_attribute(cache_column, new_value) if new_value != current_value
      end

      def initialize(parent_klass, assoc_name, relation, options)
        @parent_klass= parent_klass
        @relation = relation
        @association_name = assoc_name
        @options = options 
      end
    end

    class Count < Base

      def recalculate(parent_instance)
        parent_instance.send(@association_name).count
      end


      def my_aggregate_on(event, record)
        return if event == :update
        diff = event == :create ? 1 : -1
        aggregation_patch(diff, record)
      end

    end

    class Sum < Count
      def recalculate(parent_instance)
        parent_instance.send(@association_name).sum(child_aggregatable_field)
      end

      def my_aggregate_on(event, record)
        diff = if event == :update
          new_value(record) - old_value(record)
        else
          new_value(record) * (event == :create ? 1 : -1)
        end
        aggregation_patch(diff, record)
      end
  
    end 

    class Avg < Base
      def recalculate(parent_instance)
        parent_instance.send(@association_name).average(child_aggregatable_field)
      end
      def my_aggregate_on(event, record)
        reset_cache!(parent_instance(record)) # XXX improve this
      end
    end

    class Min < Base
      def recalculate(parent_instance)
        parent_instance.send(@association_name).minimum(child_aggregatable_field)
      end

      def my_aggregate_on(event, record)
        self.send("aggregate_on_#{event}", record)
      end

      def aggregate_on_destroy(record)
        if (new_value(record) == current_aggregation_value(record))
          reset_cache!(parent_instance(record))
        end
      end

      def aggregate_on_update(record)
        if (new_value(record) < current_aggregation_value(record))
          aggregation_replace(new_value(record), record)
        elsif (old_value(record) == current_aggregation_value(record))
          reset_cache!(parent_instance(record))
        end
      end

      def aggregate_on_create(record)
        aggregate_on_update(record)
      end
    end

    class Max < Base
      def recalculate(parent_instance)
        parent_instance.send(@association_name).maximum(child_aggregatable_field)
      end

      def my_aggregate_on(event, record)
        self.send("aggregate_on_#{event}", record)
      end

      def aggregate_on_destroy(record)
        if (current_value(record) == current_aggregation_value(record))
          reset_cache!(parent_instance(record))
        end
      end

      def aggregate_on_update(record)
        if (new_value(record) > current_aggregation_value(record))
          aggregation_replace(new_value(record), record)
        elsif (old_value(record) == current_aggregation_value(record))
          reset_cache!(parent_instance(record))
        end
      end

      def aggregate_on_create(record)
        aggregate_on_update(record)
      end

    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def aggregate_cache(assoc_name, aggr_func, options ={})
      relation = self.name.underscore

      acts_as_steroid_aggregator
      aggregator = Aggregations.factory(self, aggr_func, assoc_name, relation, options)


      has_many_association = reflect_on_association(assoc_name.to_sym)
      raise ArgumentError, "'#{self.name}' has no association called '#{association}'" unless has_many_association

      if has_many_association.is_a? ActiveRecord::Reflection::ThroughReflection
        has_many_association = has_many_association.through_reflection
      end
      
      child_class  = has_many_association.klass
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
