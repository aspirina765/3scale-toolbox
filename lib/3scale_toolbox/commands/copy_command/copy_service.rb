require 'cri'
require '3scale_toolbox/base_command'

module ThreeScaleToolbox
  module Commands
    module CopyCommand
      class CopyServiceSubcommand < Cri::CommandRunner
        include ThreeScaleToolbox::Command
        include ThreeScaleToolbox::Remotes

        def self.command
          Cri::Command.define do
            name        'service'
            usage       'service [opts] -s <src> -d <dst> <service_id>'
            summary     'Copy service'
            description 'Will create a new services, copy existing proxy settings, metrics, methods, application plans and mapping rules.'

            option  :s, :source, '3scale source instance. Format: "http[s]://<provider_key>@3scale_url"', argument: :required
            option  :d, :destination, '3scale target instance. Format: "http[s]://<provider_key>@3scale_url"', argument: :required
            option  :t, 'target_system_name', 'Target system name', argument: :required
            param   :service_id

            runner CopyServiceSubcommand
          end
        end

        def run
          source      = fetch_required_option(:source)
          destination = fetch_required_option(:destination)
          system_name = fetch_required_option(:target_system_name)

          source_service = Entities::Service.new(id: arguments[:service_id],
                                                 remote: remote(source, verify_ssl))
          target_service = create_new_service(source_service.show_service, destination, system_name)
          context = create_context(source_service, target_service)
          tasks = [
            Tasks::CopyServiceProxyTask.new(context),
            Tasks::CopyMethodsTask.new(context),
            Tasks::CopyMetricsTask.new(context),
            Tasks::CopyApplicationPlansTask.new(context),
            Tasks::CopyLimitsTask.new(context),
            Tasks::DestroyMappingRulesTask.new(context),
            Tasks::CopyMappingRulesTask.new(context)
          ]
          tasks.each(&:call)
        end

        private

        def create_context(source, target)
          {
            source: source,
            target: target
          }
        end

        def create_new_service(service, destination, system_name)
          Entities::Service.create(remote: remote(destination, verify_ssl),
                                   service: service,
                                   system_name: system_name)
        end
      end
    end
  end
end