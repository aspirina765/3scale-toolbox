module ThreeScaleToolbox
  module Entities
    class BackendMetric
      include CRD::BackendMetricSerializer

      VALID_PARAMS = %w[friendly_name system_name unit description].freeze
      public_constant :VALID_PARAMS

      METRIC_BLACKLIST = %w[id links created_at updated_at].freeze

      class << self
        def create(backend:, attrs:)
          metric = backend.remote.create_backend_metric(backend.id,
                                                        Helper.filter_params(VALID_PARAMS, attrs))
          if (errors = metric['errors'])
            raise ThreeScaleToolbox::ThreeScaleApiError.new('Backend metric has not been created',
                                                            errors)
          end

          new(id: metric.fetch('id'), backend: backend, attrs: metric)
        end

        # ref can be system_name or metric_id
        def find(backend:, ref:)
          new(id: ref, backend: backend).tap(&:attrs)
        rescue ThreeScaleToolbox::InvalidIdError, ThreeScale::API::HttpClient::NotFoundError
          find_by_system_name(backend: backend, system_name: ref)
        end

        def find_by_system_name(backend:, system_name:)
          backend.metrics.find { |m| m.system_name == system_name }
        end
      end

      attr_reader :id, :backend, :remote

      def initialize(id:, backend:, attrs: nil)
        @id = id.to_i
        @backend = backend
        @remote = backend.remote
        @attrs = process_attrs(attrs)
      end

      def attrs
        @attrs ||= process_attrs(metric_attrs)
      end

      def system_name
        attrs['system_name']
      end

      def friendly_name
        attrs['friendly_name']
      end

      def unit
        attrs['unit']
      end

      def description
        attrs['description']
      end

      def update(m_attrs)
        new_attrs = remote.update_backend_metric(backend.id, id,
                                                 Helper.filter_params(VALID_PARAMS, m_attrs))
        if (errors = new_attrs['errors'])
          raise ThreeScaleToolbox::ThreeScaleApiError.new('Backend metric has not been updated', errors)
        end

        # update current attrs
        @attrs = process_attrs(new_attrs)
      end

      def delete
        remote.delete_backend_metric backend.id, id
      end

      # enriched_key returns a metric key that will be unique for all
      # metrics from products and backends
      def enriched_key
        "backend.#{backend.id}.#{id}"
      end

      def to_hash
        extra_attrs = {
          'backend_system_name' => backend.system_name
        }

        attrs.merge(extra_attrs).reject { |key, _| METRIC_BLACKLIST.include? key }
      end

      private

      def process_attrs(metric_attrs)
        return if metric_attrs.nil?

        # system_name: my_metric_02.45498 -> system_name: my_metric_02
        metric_attrs.merge('system_name' => metric_attrs.fetch('system_name', '').partition('.').first)
      end

      def metric_attrs
        raise ThreeScaleToolbox::InvalidIdError if id.zero?

        metric = remote.backend_metric backend.id, id
        if (errors = metric['errors'])
          raise ThreeScaleToolbox::ThreeScaleApiError.new('Backend metric not read', errors)
        end

        metric
      end
    end
  end
end
