require_relative "event_transitions"

# Adds support for events when `extend`ed into state machine classes
module Statesman
  module Events
    def self.included(base)
      unless base.respond_to?(:states)
        raise "Statesman::Events included before/without Statesman::Machine"
      end
      base.extend(ClassMethods)
    end

    module ClassMethods
      def events
        @events ||= {}
      end

      def event(name, &block)
        EventTransitions.new(self, name, &block)
      end
    end

    def trigger!(event_name, metadata = {})
      transitions = self.class.events.fetch(event_name) do
        raise Statesman::TransitionFailedError,
              "Event #{event_name} not found"
      end

      new_state = transitions.fetch(current_state) do
        raise Statesman::TransitionFailedError,
              "State #{current_state} not found for Event #{event_name}"
      end

      transition_to!(new_state.first, metadata)
    end

    def trigger(event_name, metadata = {})
      self.trigger!(event_name, metadata)
    rescue Statesman::TransitionFailedError, Statesman::GuardFailedError
      false
    end

    def available_events
      state = current_state
      self.class.events.select do |_, transitions|
        transitions.key?(state)
      end.map(&:first)
    end
  end
end
