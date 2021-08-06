module Graphiti
  module Middleware
    class Chain
      include Enumerable

      def each(&block)
        entries.each(&block)
      end

      def initialize
        @entries = nil
        yield self if block_given?
      end

      def entries
        @entries ||= []
      end

      def remove(klass)
        entries.delete_if { |entry| entry == klass }
      end

      def add(klass)
        remove(klass)
        entries << klass
      end

      def prepend(klass)
        remove(klass)
        entries.insert(0, klass)
      end

      def insert_before(oldklass, newklass)
        i = entries.index { |entry| entry == newklass }
        new_entry = i.nil? ? newklass : entries.delete_at(i)
        i = entries.index { |entry| entry == oldklass } || 0
        entries.insert(i, new_entry)
      end

      def insert_after(oldklass, newklass)
        i = entries.index { |entry| entry == newklass }
        new_entry = i.nil? ? newklass : entries.delete_at(i)
        i = entries.index { |entry| entry.klass == oldklass } || entries.count - 1
        entries.insert(i + 1, new_entry)
      end

      def empty?
        @entries.nil? || @entries.empty?
      end

      def prepare(sideload, context)
        return context if empty?

        entries.each do |entry|
          entry.prepare(sideload, context) if entry.respond_to?(:prepare)
        end

        context
      end

      def call
        return yield if empty?

        traverse_chain = proc do
          if entries.empty?
            yield
          else
            entries.shift.call(&traverse_chain)
          end
        end
        traverse_chain.call
      end
    end
  end
end
