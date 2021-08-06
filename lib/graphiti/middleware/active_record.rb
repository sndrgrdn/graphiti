module Graphiti
  module Middleware
    class ActiveRecord
      def self.call
        if (connection_handler = Graphiti.context[:ar_connection_handler])
          ::ActiveRecord::Base.connection_handler = connection_handler
        end

        if (connection_handlers = Graphiti.context[:ar_connection_handlers])
          ::ActiveRecord::Base.connection_handlers = connection_handlers
        end

        if (connected_to_stack = Graphiti.context[:ar_connected_to_stack])
          context[:ar_model].connected_to_stack = connected_to_stack
        end

        yield
      end

      def self.prepare(sideload, context)
        return unless sideload.resource_class.adapter == Graphiti::Adapters::ActiveRecord

        context.merge!(ar_model: sideload.resource_class.model)
        context.merge!(ar_connection_handler: ::ActiveRecord::Base.connection_handler)

        if sideload.resource_class.model.respond_to?(:connected_to_stack) &&
           !::ActiveRecord::Base.legacy_connection_handling

          context[:ar_connected_to_stack] = sideload.resource_class.model.connected_to_stack
        else
          context.merge!(ar_connection_handlers: ::ActiveRecord::Base.connection_handlers)
        end
      end
    end
  end
end
