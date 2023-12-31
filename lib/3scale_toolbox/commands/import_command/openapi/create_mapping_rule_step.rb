module ThreeScaleToolbox
  module Commands
    module ImportCommand
      module OpenAPI
        class CreateMappingRulesStep
          include Step

          def call
            report['mapping_rules'] = {}
            operations.each do |op|
              Entities::MappingRule.create(service: service,
                                           attrs: op.mapping_rule)
              logger.info "Created #{op.http_method} #{op.pattern} endpoint"
              report['mapping_rules'][op.friendly_name] = op.mapping_rule
            end
          end
        end
      end
    end
  end
end
