module SurfaceMaster
  module Launchpad
    # Higher-level interface to Novation Launchpad Mark 2, providing an input
    # handling loop and event-hooks for input events.
    class Interaction < SurfaceMaster::Interaction
      def initialize(opts = nil)
        @device_class = Device
        super(opts)
      end

    protected

      def responses
        @responses ||= Hash.new { |hash, key| hash[key] = { down: [], up: [] } }
      end

      def grid_range(range)
        return nil if range.nil?
        Array(range).flatten.map do |pos|
          pos.respond_to?(:to_a) ? pos.to_a : pos
        end.flatten.uniq
      end

      def combined_types(type, opts = nil)
        if type.to_sym == :grid && opts
          x = grid_range(opts[:x])
          y = grid_range(opts[:y])
          return [:grid] if x.nil? && y.nil?  # whole grid
          x ||= ["-"]                         # whole row
          y ||= ["-"]                         # whole column
          x.product(y).map { |xx, yy| :"grid#{xx}#{yy}" }
        else
          [type.to_sym]
        end
      end

      def respond_to_action(action)
        mappings_for_action(action).each do |block|
          block.call(self, action)
        end
        nil
      rescue StandardError => e # TODO: StandardException, RuntimeError, or Exception?
        logger.error "Error when responding to action #{action.inspect}: #{e.inspect}"
        raise e
      end

      def mappings_for_action(action)
        type, state     = action.slice(:type, :state).map(&:to_sym)
        actions         = []
        actions        += mappings_for_grid_action(state, action[:x], action[:y]) if type == :grid
        actions        += responses[type][state]
        actions        += responses[:all][state]
        actions.compact
      end

      def mappings_for_grid_action(state, x, y)
        actions = []
        actions += responses[:"grid#{x}#{y}"][state]
        actions += responses[:"grid#{x}-"][state]
        actions += responses[:"grid-#{y}"][state]
        actions
      end
    end
  end
end
