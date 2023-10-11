require 'active_graph/core/querable'
require 'active_graph/core/schema'

module ActiveGraph
  # To contain any base login for Node/Relationship which
  # is external to the main classes
  module Base
    include ActiveGraph::Transactions
    include ActiveGraph::Core::Querable
    extend ActiveGraph::Core::Schema

    DriverNotDefinedError = Class.new(StandardError)

    at_exit do
      ActiveGraph::Tenant.driver&.close
    end

    class << self

      def driver
        ActiveGraph::Tenant.driver || fail(DriverNotDefinedError.new("Neo4j driver not defined, assign ActiveGraph::Tenant.tenant_id"))
      end

      def query(*args)
        transaction(implicit: true) do
          super(*args)
        end
      end

      def validating_transaction(&block)
        validate_model_schema!
        transaction(&block)
      end

      def new_query(options = {})
        validate_model_schema!
        ActiveGraph::Core::Query.new(options)
      end

      def magic_query(*args)
        if args.empty? || args.map(&:class) == [Hash]
          new_query(*args)
        else
          query(*args)
        end
      end

      def label_object(label_name)
        ActiveGraph::Core::Label.new(label_name)
      end

      def logger
        @logger ||= (ActiveGraph::Config[:logger] || ActiveSupport::Logger.new(STDOUT))
      end

      private

      def validate_model_schema!
        ActiveGraph::ModelSchema.validate_model_schema! unless ActiveGraph::Migrations.currently_running_migrations
      end
    end
  end
end
