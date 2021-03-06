module SurfaceMaster
  # Base class for event-based drivers.  Sub-classes should extend the constructor, and implement
  # `respond_to_action`, etc.
  class Interaction
    include Logging

    attr_reader :device, :active

    def initialize(opts = nil)
      opts ||= {}

      self.logger = opts[:logger]
      logger.debug "Initializing #{self.class}##{object_id} with #{opts.inspect}"

      @device       = opts[:device] || @device_class.new(opts.merge(input: true,
                                                                    output: true,
                                                                    logger: opts[:logger]))
      @latency      = (opts[:latency] || 0.001).to_f.abs
      @active       = false
    end

    def change(opts); @device.change(opts); end
    def changes(opts); @device.changes(opts); end

    def close
      logger.debug "Closing #{self.class}##{object_id}"
      stop
      @device.close
    end

    def closed?; @device.closed?; end

    def start
      logger.debug "Starting #{self.class}##{object_id}"

      @active = true
      guard_input_and_reset_at_end! do
        while @active
          @device.read.each { |action| respond_to_action(action) }
          sleep @latency if @latency && @latency > 0.0
        end
      end
    end

    def stop
      logger.debug "Stopping #{self.class}##{object_id}"
      @active = false
    end

    def response_to(types = :all, state = :both, opts = nil, &block)
      logger.debug "Setting response to #{types.inspect} for state #{state.inspect} with"\
        " #{opts.inspect}"
      types   = Array(types)
      opts  ||= {}
      no_response_to(types, state, opts) if opts[:exclusive] == true
      expand_states(state).each do |st|
        add_response_for_state!(types, opts, st, block)
      end
      nil
    end

    def no_response_to(types = nil, state = :both, opts = nil)
      logger.debug "Removing response to #{types.inspect} for state #{state.inspect}"
      types   = Array(types)
      opts  ||= {}
      expand_states(state).each do |st|
        clear_responses_for_state!(types, opts, st)
      end
      nil
    end

    def respond_to(type, state, opts = nil)
      respond_to_action((opts || {}).merge(type: type, state: state))
    end

  protected

    def expand(list)
      Array(list).map { |ll| ll.respond_to?(:to_a) ? ll.to_a : ll }.flatten
    end

    def guard_input_and_reset_at_end!(&_block)
      yield
    rescue Portmidi::DeviceError => e
      logger.fatal "Could not read from device, stopping reader!"
      raise SurfaceMaster::CommunicationError, e
    rescue Exception => e
      logger.fatal "Unkown error, stopping reader: #{e.inspect}"
      raise e
    ensure
      @device.reset!
    end

    def add_response_for_state!(types, opts, state, block)
      response_groups_for(types, opts, state) do |responses|
        responses << block
      end
    end

    def clear_responses_for_state!(types, opts, state)
      response_groups_for(types, opts, state, &:clear)
    end

    def response_groups_for(types, opts, state, &_block)
      types.each do |type|
        combined_types(type, opts).each do |combined_type|
          yield(responses[combined_type][state])
        end
      end
    end

    def expand_states(state); Array(state == :both ? %i(down up) : state); end

    def responses
      # TODO: Generalize for arbitrary actions...
      @responses ||= Hash.new { |hash, key| hash[key] = { down: [], up: [] } }
    end

    def respond_to_action(_action); end
  end
end
