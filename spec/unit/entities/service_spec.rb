RSpec.describe ThreeScaleToolbox::Entities::Service do
  include_context :random_name
  let(:remote) { instance_double('ThreeScale::API::Client', 'remote') }
  let(:common_error_response) { { 'errors' => { 'comp' => 'error' } } }
  let(:positive_response) { { 'errors' => nil, 'id' => 1000 } }

  context 'Service.create' do
    let(:system_name) { random_lowercase_name }
    let(:deployment_option) { 'hosted' }
    let(:service) do
      {
        'name' => random_lowercase_name,
        'deployment_option' => deployment_option,
        'system_name' => system_name,
      }
    end
    let(:service_info) { { remote: remote, service_params: service } }
    let(:expected_svc) { { 'name' => service['name'], 'system_name' => system_name } }

    it 'throws error on remote error' do
      expect(remote).to receive(:create_service).and_return(common_error_response)
      expect do
        described_class.create(**service_info)
      end.to raise_error(ThreeScaleToolbox::Error, /Service has not been created/)
    end

    context 'deployment mode invalid' do
      let(:invalid_deployment_error_response) do
        {
          'errors' => {
            'deployment_option' => ['is not included in the list']
          }
        }
      end

      it 'deployment config is removed' do
        expect(remote).to receive(:create_service).with(hash_including('deployment_option'))
                                                  .and_return(invalid_deployment_error_response)
        expect(remote).to receive(:create_service).with(hash_excluding('deployment_option'))
                                                  .and_return(positive_response)
        service_obj = described_class.create(**service_info)
        expect(service_obj.id).to eq(positive_response['id'])
      end

      it 'throws error when second request returns error' do
        expect(remote).to receive(:create_service).with(hash_including('deployment_option'))
                                                  .and_return(invalid_deployment_error_response)
        expect(remote).to receive(:create_service).with(hash_excluding('deployment_option'))
                                                  .and_return(common_error_response)
        expect do
          described_class.create(**service_info)
        end.to raise_error(ThreeScaleToolbox::Error, /Service has not been created/)
      end
    end

    it 'throws deployment option error' do
      expect(remote).to receive(:create_service).and_return(common_error_response)
      expect do
        described_class.create(**service_info)
      end.to raise_error(ThreeScaleToolbox::Error, /Service has not been created/)
    end

    it 'service instance is returned' do
      expect(remote).to receive(:create_service).and_return(positive_response)
      service_obj = described_class.create(**service_info)
      expect(service_obj.id).to eq(1000)
      expect(service_obj.remote).to be(remote)
    end
  end

  context 'Service.find' do
    let(:system_name) { random_lowercase_name }
    let(:service_id) { 10001 }
    let(:service_info) { { remote: remote, ref: system_name } }

    it 'remote call raises unexpected error' do
      expect(remote).to receive(:list_services).and_raise(StandardError)
      expect do
        described_class.find(**service_info)
      end.to raise_error(StandardError)
    end

    it 'returns nil when the service does not exist' do
      expect(remote).to receive(:list_services).and_return([{ "system_name" => "sysname1" }, { "system_name" => "sysname2" }])
      expect(described_class.find(**service_info)).to be_nil
    end

    it 'service instance is returned when specifying an existing service ID' do
      expect(remote).to receive(:show_service).and_return({ "id" => service_id, "system_name" => "sysname1" })
      service_obj = described_class.find(remote: remote, ref: service_id)
      expect(service_obj.id).to eq(service_id)
      expect(service_obj.remote).to be(remote)
    end

    it 'service instance is returned when specifying an existing system-name' do
      expect(remote).to receive(:list_services).and_return([{ "id" => 3, "system_name" => system_name }, { "id" => 7, "system_name" => "sysname1" }])
      service_obj = described_class.find(**service_info)
      expect(service_obj).to be
      expect(service_obj.id).to eq(3)
      expect(service_obj.remote).to be(remote)
    end

    it 'service instance is returned from service ID in front of an existing service with the same system-name as the ID' do
      svc_info = { remote: remote, ref: 3 }
      expect(remote).to receive(:show_service).and_return("id" => svc_info[:ref], "system_name" => "sysname1")
      allow(remote).to receive(:list_services).and_return([{ "id" => 4, "system_name" => svc_info[:ref] }, { 'id' => 5, "system_name" => "sysname2" }])
      service_obj = described_class.find(**svc_info)
      expect(service_obj.id).to eq(svc_info[:ref])
      expect(service_obj.remote).to be(remote)
    end
  end

  context 'Service.find_by_system_name' do
    let(:system_name) { random_lowercase_name }
    let(:service_info) { { remote: remote, system_name: system_name } }

    it 'an exception is raised when remote is not configured' do
      expect(remote).to receive(:list_services).and_raise(StandardError)
      expect do
        described_class.find_by_system_name(**service_info)
      end.to raise_error(StandardError)
    end

    it 'returns nil when the service does not exist' do
      expect(remote).to receive(:list_services).and_return([{ "system_name" => "sysname1" }, { "system_name" => "sysname2" }])
      expect(described_class.find_by_system_name(**service_info)).to be_nil
    end

    it 'service instance is returned when specifying an existing system-name' do
      expect(remote).to receive(:list_services).and_return([{ "id" => 3, "system_name" => system_name }, { "id" => 7, "system_name" => "sysname1" }])
      service_obj = described_class.find_by_system_name(**service_info)
      expect(service_obj.id).to eq(3)
      expect(service_obj.remote).to be(remote)
    end

    context 'when remote returns error' do
      before :each do
        expect(remote).to receive(:list_services).and_return('errors' => 'some error')
      end

      it 'ThreeScaleApiError is raised' do
        expect { described_class.find_by_system_name(**service_info) }.to raise_error(ThreeScaleToolbox::ThreeScaleApiError)
      end
    end

    context 'when service list length is' do
      subject { described_class.find_by_system_name(remote: remote, system_name: system_name) }
      let(:expected_service_id) { 0 }

      context 'MAX_SERVICES_PER_PAGE - 1' do
        let(:service_response) do
          # the latest service is the one with the searched system_name
          (1..ThreeScale::API::MAX_SERVICES_PER_PAGE - 2).map do |idx|
            { 'id' => idx, 'system_name' => idx.to_s }
          end + [{ 'id' => expected_service_id, 'system_name' => system_name }]
        end

        it 'then 1 remote call' do
          expect(remote).to receive(:list_services).with(page: 1, per_page: ThreeScale::API::MAX_SERVICES_PER_PAGE).and_return(service_response)

          expect(subject.id).to eq expected_service_id
        end
      end

      context 'MAX_SERVICES_PER_PAGE' do
        let(:service_response01) do
          # the latest service is the one with the searched system_name
          (1..ThreeScale::API::MAX_SERVICES_PER_PAGE - 1).map do |idx|
            { 'id' => idx, 'system_name' => idx.to_s }
          end + [{ 'id' => expected_service_id, 'system_name' => system_name }]
        end
        let(:service_response02) { [] }

        it 'then 2 remote call' do
            expect(remote).to receive(:list_services).with(page: 1, per_page: ThreeScale::API::MAX_SERVICES_PER_PAGE).and_return(service_response01)
            expect(remote).to receive(:list_services).with(page: 2, per_page: ThreeScale::API::MAX_SERVICES_PER_PAGE).and_return(service_response02)

            expect(subject.id).to eq expected_service_id
        end
      end

      context 'MAX_SERVICES_PER_PAGE + 1' do
        let(:service_response01) do
          (1..ThreeScale::API::MAX_SERVICES_PER_PAGE).map do |idx|
            { 'id' => idx, 'system_name' => idx.to_s }
          end
        end
        # the latest service is the one with the searched system_name
        let(:service_response02) { [{ 'id' => expected_service_id, 'system_name' => system_name }] }

        it 'then 2 remote call' do
            expect(remote).to receive(:list_services).with(page: 1, per_page: ThreeScale::API::MAX_SERVICES_PER_PAGE).and_return(service_response01)
            expect(remote).to receive(:list_services).with(page: 2, per_page: ThreeScale::API::MAX_SERVICES_PER_PAGE).and_return(service_response02)

            expect(subject.id).to eq expected_service_id
        end
      end

      context '2 * MAX_SERVICES_PER_PAGE' do
        let(:service_response01) do
          (1..ThreeScale::API::MAX_SERVICES_PER_PAGE).map do |idx|
            { 'id' => idx, 'system_name' => idx.to_s }
          end
        end
        let(:service_response02) do
          # the latest service is the one with the searched system_name
          (1..ThreeScale::API::MAX_SERVICES_PER_PAGE - 1).map do |idx|
            { 'id' => ThreeScale::API::MAX_SERVICES_PER_PAGE + idx, 'system_name' => (ThreeScale::API::MAX_SERVICES_PER_PAGE + idx).to_s }
          end + [{ 'id' => expected_service_id, 'system_name' => system_name }]
        end
        let(:service_response03) { [] }

        it 'then 3 remote call' do
            expect(remote).to receive(:list_services).with(page: 1, per_page: ThreeScale::API::MAX_SERVICES_PER_PAGE).and_return(service_response01)
            expect(remote).to receive(:list_services).with(page: 2, per_page: ThreeScale::API::MAX_SERVICES_PER_PAGE).and_return(service_response02)
            expect(remote).to receive(:list_services).with(page: 3, per_page: ThreeScale::API::MAX_SERVICES_PER_PAGE).and_return(service_response03)

            expect(subject.id).to eq expected_service_id
        end
      end

      context '2 * MAX_SERVICES_PER_PAGE + 1' do
        let(:service_response01) do
          (1..ThreeScale::API::MAX_SERVICES_PER_PAGE).map do |idx|
            { 'id' => idx, 'system_name' => idx.to_s }
          end
        end
        let(:service_response02) do
          # the latest service is the one with the searched system_name
          (1..ThreeScale::API::MAX_SERVICES_PER_PAGE).map do |idx|
            { 'id' => ThreeScale::API::MAX_SERVICES_PER_PAGE + idx, 'system_name' => (ThreeScale::API::MAX_SERVICES_PER_PAGE + idx).to_s }
          end
        end
        let(:service_response03) { [{ 'id' => expected_service_id, 'system_name' => system_name }] }

        it 'then 3 remote call' do
            expect(remote).to receive(:list_services).with(page: 1, per_page: ThreeScale::API::MAX_SERVICES_PER_PAGE).and_return(service_response01)
            expect(remote).to receive(:list_services).with(page: 2, per_page: ThreeScale::API::MAX_SERVICES_PER_PAGE).and_return(service_response02)
            expect(remote).to receive(:list_services).with(page: 3, per_page: ThreeScale::API::MAX_SERVICES_PER_PAGE).and_return(service_response03)

            expect(subject.id).to eq expected_service_id
        end
      end
    end
  end

  context 'instance method' do
    let(:id) { 774 }
    let(:hits_metric) { { 'id' => 1, 'system_name' => 'hits' } }
    let(:metrics) do
      [
        { 'id' => 10, 'system_name' => 'metric_10' },
        hits_metric,
        { 'id' => 20, 'system_name' => 'metric_20' }
      ]
    end
    let(:methods) do
      [
        { 'id' => 101, 'system_name' => 'method_101', 'parent_id' => 1 },
        { 'id' => 201, 'system_name' => 'method_201', 'parent_id' => 1 }
      ]
    end
    let(:proxy) { { 'id' => 201 } }
    let(:attrs) { nil }

    subject { described_class.new(id: id, remote: remote, attrs: attrs) }

    context '#attrs' do
      it 'calls show_service method' do
        expect(remote).to receive(:show_service).with(id).and_return({})
        subject.attrs
      end
    end

    context '#update_proxy' do
      it 'calls update_proxy method' do
        expect(remote).to receive(:update_proxy).with(id, proxy).and_return(proxy)
        expect(subject.update_proxy(proxy)).to eq(proxy)
      end
    end

    context '#proxy' do
      it 'calls show_proxy method' do
        expect(remote).to receive(:show_proxy).with(id).and_return(proxy)
        expect(subject.proxy).to eq(proxy)
      end
    end

    context '#metrics' do
      it 'returns only metrics' do
        allow(remote).to receive(:list_metrics).with(id).and_return(metrics + methods)
        allow(remote).to receive(:list_methods).with(id, 1).and_return(methods)
        expect(subject.metrics.map(&:attrs)).to eq(metrics)
      end
    end

    context '#hits' do
      it 'raises error if metric not found' do
        expect(remote).to receive(:list_metrics).with(id).and_return([])
        expect { subject.hits }.to raise_error(ThreeScaleToolbox::Error, /missing hits metric/)
      end

      it 'return hits metric' do
        expect(remote).to receive(:list_metrics).with(id).and_return(metrics + methods)
        expect(subject.hits.attrs).to be(hits_metric)
      end
    end

    context '#methods' do
      it 'calls list_methods method' do
        allow(remote).to receive(:list_metrics).with(id).and_return(metrics + methods)
        expect(remote).to receive(:list_methods).with(id, hits_metric['id']).and_return(methods)
        expect(subject.methods.map(&:attrs)).to eq(methods)
      end
    end

    context '#plans' do
      it 'calls list_service_application_plans method' do
        expect(remote).to receive(:list_service_application_plans).with(id).and_return([])
        subject.plans
      end
    end

    context '#mapping_rules' do
      it 'calls list_mapping_rules method' do
        expect(remote).to receive(:list_mapping_rules).with(id).and_return([])
        subject.mapping_rules
      end
    end

    context '#update' do
      let(:params) { { 'name' => 'new name' } }
      let(:new_params) { { 'id' => 5, 'name' => 'new_name' } }

      context 'remote call successfull' do
        before :example do
          expect(remote).to receive(:update_service).with(id, params).and_return(new_params)
        end

        it 'returns new params' do
          expect(subject.update(params)).to eq(new_params)
        end

        it 'attrs method returns new params' do
          subject.update(params)
          expect(subject.attrs).to eq(new_params)
        end
      end

      context 'new attrs include invalid deployment option' do
        let(:params) { { 'name' => 'new name', 'deployment_option' => 'self_managed' } }
        let(:invalid_deployment_mode_error) do
          {
            'errors' => {
              'deployment_option' => ['is not included in the list']
            }
          }
        end

        before :example do
          expect(remote).to receive(:update_service).with(id, params)
                                                    .and_return(invalid_deployment_mode_error)
        end

        it 'second update call with deployment mode attr removed' do
          sanitized_params = params.dup.tap { |hs| hs.delete('deployment_option') }
          expect(remote).to receive(:update_service).with(id, sanitized_params)
                                                    .and_return(new_params)
          expect(subject.update(params)).to eq(new_params)
        end
      end
    end

    context '#policies' do
      it 'calls show_policies method' do
        expect(remote).to receive(:show_policies).with(id)
        subject.policies
      end
    end

    context '#update_policies' do
      let(:params) { [] }
      it 'calls update_policies method' do
        expect(remote).to receive(:update_policies).with(id, params)
        subject.update_policies(params)
      end
    end

    context '#activedocs' do
      let(:owned_activedocs0) { instance_double(ThreeScaleToolbox::Entities::ActiveDocs, 'activedocs0') }
      let(:owned_activedocs0_attrs) do
        {
          'id' => 0, 'name' => 'ad_0', 'system_name' => 'ad_0', 'service_id' => id
        }
      end
      let(:owned_activedocs1) { instance_double(ThreeScaleToolbox::Entities::ActiveDocs, 'activedocs1') }
      let(:owned_activedocs1_attrs) do
        {
          'id' => 1, 'name' => 'ad_1', 'system_name' => 'ad_1', 'service_id' => id
        }
      end
      let(:not_owned_activedocs) { instance_double(ThreeScaleToolbox::Entities::ActiveDocs, 'not_owned_activedocs') }
      let(:not_owned_activedocs_attrs) do
        {
          'id' => 2, 'name' => 'ad_2', 'system_name' => 'ad_2', 'service_id' => 'other'
        }
      end
      let(:activedocs) { [owned_activedocs0_attrs, owned_activedocs1_attrs, not_owned_activedocs_attrs] }

      it 'filters activedocs not owned by service' do
        expect(remote).to receive(:list_activedocs).and_return(activedocs)
        expect(subject.activedocs.map(&:attrs)).to match_array([owned_activedocs0_attrs, owned_activedocs1_attrs])
      end
    end

    context '#proxy_configs' do
      it 'returns an error on remote error' do
        expect(remote).to receive(:proxy_config_list).and_return(common_error_response)
        expect { subject.proxy_configs("sandbox") }.to raise_error(ThreeScaleToolbox::ThreeScaleApiError, /ProxyConfigs not read/)
      end

      it 'returns an empty array when there are no proxy_configs in an environment' do
        expect(remote).to receive(:proxy_config_list).with(id, "sandbox").and_return([])
        results = subject.proxy_configs("sandbox")
        expect(results.size).to eq(0)
      end

      context "when sandbox environment is requested" do
        let(:owned_proxy_config_sandbox_0) { { "id" => 3, "environment" => "sandbox", "version" => 0} }
        let(:owned_proxy_config_sandbox_1) { { "id" => 4, "environment" => "sandbox", "version" => 1} }
        let(:environment) { "sandbox" }

        it 'returns the expected ProxyConfig entities' do
          expect(remote).to receive(:proxy_config_list).with(id, environment).and_return([owned_proxy_config_sandbox_0, owned_proxy_config_sandbox_1])
          results = subject.proxy_configs(environment)
          expect(results.size).to eq(2)
          pc_0 = results[0]
          pc_1 = results[1]
          expect(pc_0).to be_a(ThreeScaleToolbox::Entities::ProxyConfig)
          expect(pc_1).to be_a(ThreeScaleToolbox::Entities::ProxyConfig)
          expect(pc_0.attrs['id']).to eq(3)
          expect(pc_0.attrs['environment']).to eq(environment)
          expect(pc_0.attrs['version']).to eq(0)
          expect(pc_1.attrs['id']).to eq(4)
          expect(pc_1.attrs['environment']).to eq(environment)
          expect(pc_1.attrs['version']).to eq(1)
        end
      end

      context "when production environment is requested" do
        let(:owned_proxy_config_production_0) { { "id" => 0, "environment" => "production", "version" => 0} }
        let(:owned_proxy_config_production_1) { { "id" => 1, "environment" => "production", "version" => 1} }
        let(:environment) { "production" }
        it 'returns the expected ProxyConfig entities' do
          expect(remote).to receive(:proxy_config_list).with(id, environment).and_return([owned_proxy_config_production_0, owned_proxy_config_production_1])
          results = subject.proxy_configs(environment)
          expect(results.size).to eq(2)
          pc_0 = results[0]
          pc_1 = results[1]
          expect(pc_0).to be_a(ThreeScaleToolbox::Entities::ProxyConfig)
          expect(pc_1).to be_a(ThreeScaleToolbox::Entities::ProxyConfig)
          expect(pc_0.attrs['id']).to eq(0)
          expect(pc_0.attrs['environment']).to eq(environment)
          expect(pc_0.attrs['version']).to eq(0)
          expect(pc_1.attrs['id']).to eq(1)
          expect(pc_1.attrs['environment']).to eq(environment)
          expect(pc_1.attrs['version']).to eq(1)
        end
      end
    end

    context 'oidc' do
      let(:oidc_configuration) do
        {
          standard_flow_enabled: false,
          implicit_flow_enabled: true,
          service_accounts_enabled: false,
          direct_access_grants_enabled: false
        }
      end

      context '#oidc' do
        it 'calls show_oidc method' do
          expect(remote).to receive(:show_oidc).with(id).and_return(oidc_configuration)
          expect(subject.oidc).to eq(oidc_configuration)
        end
      end

      context '#update_oidc' do
        it 'calls update_oidc method' do
          expect(remote).to receive(:update_oidc).with(id, oidc_configuration).and_return(oidc_configuration)
          expect(subject.update_oidc(oidc_configuration)).to eq(oidc_configuration)
        end
      end

      context '#applications' do
        context 'list_applications returns error' do
          let(:request_error) { { 'errors' => 'some error' } }

          before :example do
            expect(remote).to receive(:list_applications).with(service_id: id)
                                                         .and_return(request_error)
          end

          it 'error is raised' do
            expect { subject.applications }.to raise_error(ThreeScaleToolbox::ThreeScaleApiError,
                                                           /Service applications not read/)
          end
        end

        context 'list_applications returns applications' do
          let(:app01_attrs) { { 'id' => 1, 'name' => 'app01' } }
          let(:app02_attrs) { { 'id' => 2, 'name' => 'app02' } }
          let(:app03_attrs) { { 'id' => 3, 'name' => 'app03' } }
          let(:applications) { [app01_attrs, app02_attrs, app03_attrs] }

          before :example do
            expect(remote).to receive(:list_applications).with(service_id: id)
                                                         .and_return(applications)
          end

          it 'app01 is returned' do
            apps = subject.applications
            expect(apps.map(&:id)).to include(1)
          end

          it 'app02 is returned' do
            apps = subject.applications
            expect(apps.map(&:id)).to include(2)
          end

          it 'app03 is returned' do
            apps = subject.applications
            expect(apps.map(&:id)).to include(3)
          end
        end
      end

      context 'equality method' do
        let(:svc1) { described_class.new(id: id1, remote: remote1) }
        let(:svc2) { described_class.new(id: id2, remote: remote2) }
        let(:remote1) { instance_double(ThreeScale::API::Client, 'remote1') }
        let(:remote2) { instance_double(ThreeScale::API::Client, 'remote2') }
        let(:http_client1) { instance_double(ThreeScale::API::HttpClient, 'httpclient1') }
        let(:http_client2) { instance_double(ThreeScale::API::HttpClient, 'httpclient2') }

        before :example do
          allow(remote1).to receive(:http_client).and_return(http_client1)
          allow(remote2).to receive(:http_client).and_return(http_client2)
          allow(http_client1).to receive(:endpoint).and_return(endpoint1)
          allow(http_client2).to receive(:endpoint).and_return(endpoint2)
        end

        context 'same remote, diff id' do
          let(:id1) { 1 }
          let(:id2) { 2 }
          let(:endpoint1) { 'https://w1.example.com' }
          let(:endpoint2) { 'https://w1.example.com' }

          it 'are not equal' do
            expect(svc1).not_to eq(svc2)
          end
        end

        context 'same remote, same id' do
          let(:id1) { 1 }
          let(:id2) { 1 }
          let(:endpoint1) { 'https://w1.example.com' }
          let(:endpoint2) { 'https://w1.example.com' }

          it 'are equal' do
            expect(svc1).to eq(svc2)
          end
        end

        context 'diff remote, same id' do
          let(:id1) { 1 }
          let(:id2) { 1 }
          let(:endpoint1) { 'https://w1.example.com' }
          let(:endpoint2) { 'https://w2.example.com' }

          it 'are not equal' do
            expect(svc1).not_to eq(svc2)
          end
        end

        context 'diff remote, diff id' do
          let(:id1) { 1 }
          let(:id2) { 2 }
          let(:endpoint1) { 'https://w1.example.com' }
          let(:endpoint2) { 'https://w2.example.com' }

          it 'are not equal' do
            expect(svc1).not_to eq(svc2)
          end
        end
      end
    end

    context '#proxy_deploy' do
      let(:proxy_attrs) do
        {
          'service_id' => id,
          'endpoint' => 'https://example.com:443',
        }
      end

      it 'calls proxy_deploy method' do
        expect(remote).to receive(:proxy_deploy).with(id).and_return(proxy_attrs)
        expect(subject.proxy_deploy).to eq(proxy_attrs)
      end

      it 'raises error on remote error' do
        expect(remote).to receive(:proxy_deploy).with(id).and_return(common_error_response)
        expect { subject.proxy_deploy }.to raise_error(ThreeScaleToolbox::Error)
      end
    end

    context '#metrics_mapping' do
      let(:backend) { instance_double(ThreeScaleToolbox::Entities::Backend, 'backend') }
      let(:other_backend) { instance_double(ThreeScaleToolbox::Entities::Backend, 'other_backend') }
      let(:backend_usage_class) { class_double(ThreeScaleToolbox::Entities::BackendUsage).as_stubbed_const }
      let(:backend_usage) { instance_double(ThreeScaleToolbox::Entities::BackendUsage, 'backend_usage') }
      let(:backend_usage_attrs) { { 'id' => 1 } }
      let(:backend_usage_list) { [backend_usage_attrs] }
      let(:other_backend_usage) { instance_double(ThreeScaleToolbox::Entities::BackendUsage, 'other_backend_usage') }
      let(:other_backend_usage_attrs) { { 'id' => 2 } }
      let(:other_backend_usage_list) { [other_backend_usage_attrs] }
      let(:other_remote) { instance_double(ThreeScale::API::Client, 'other_remote') }
      let(:other_id) { 5 }
      let(:other) { described_class.new(id: other_id, remote: other_remote) }
      let(:other_hits_metric) { { 'id' => 10, 'system_name' => 'hits' } }
      let(:other_metrics) do
        [
          { 'id' => 110, 'system_name' => 'metric_10' },
          other_hits_metric,
          { 'id' => 120, 'system_name' => 'metric_20' },
          { 'id' => 130, 'system_name' => 'other_metric_20' }
        ]
      end

      before :example do
        allow(backend_usage_class).to receive(:new).with(hash_including(id: 1)).and_return(backend_usage)
        allow(backend_usage_class).to receive(:new).with(hash_including(id: 2)).and_return(other_backend_usage)
        allow(backend_usage).to receive(:backend).and_return(backend)
        allow(other_backend_usage).to receive(:backend).and_return(other_backend)
        allow(backend).to receive(:system_name).and_return('mybackend')
        allow(other_backend).to receive(:system_name).and_return('mybackend')
        allow(backend).to receive(:metrics_mapping).with(other_backend).and_return(40 => 140)
        allow(remote).to receive(:list_metrics).with(id).and_return(metrics + methods)
        allow(remote).to receive(:list_methods).with(id, 1).and_return(methods)
        allow(remote).to receive(:list_backend_usages).with(id).and_return(backend_usage_list)
        allow(other_remote).to receive(:list_metrics).with(other_id).and_return(other_metrics)
        allow(other_remote).to receive(:list_methods).with(other_id, 10).and_return([])
        allow(other_remote).to receive(:list_backend_usages).with(other_id).and_return(other_backend_usage_list)
      end

      it 'computes metrics mapping' do
        expect(subject.metrics_mapping(other)).to eq({
          1 => 10,
          10 => 110,
          20 => 120,
          40 => 140
        })
      end
    end

    context '#backend_usage_list' do
      it 'calls list_backend_usages method' do
        expect(remote).to receive(:list_backend_usages).with(id).and_return([])
        subject.backend_usage_list
      end
    end

    context '#to_cr' do
      let(:attrs) do
        {
          'id' => id, 'name' => 'some name', 'system_name' => 'myservice',
          'description' => 'some descr', 'deployment_option' => 'hosted', 'backend_version' => '1'
        }
      end
      let(:plan_attr_list) do
        [
          { 'id' => 1, 'system_name' => 'plan01' },
          { 'id' => 2, 'system_name' => 'plan02' },
          { 'id' => 3, 'system_name' => 'plan03' }
        ]
      end
      let(:plan_class) { class_double(ThreeScaleToolbox::Entities::ApplicationPlan).as_stubbed_const }
      let(:plans) do
        plan_attr_list.map do |plan_attrs|
          instance_double(ThreeScaleToolbox::Entities::ApplicationPlan, plan_attrs.fetch('system_name'))
        end
      end
      let(:backend_usage_attr_list) { [ { 'id' => 1 }, { 'id' => 2 }, { 'id' => 3 } ] }
      let(:backend_usage_class) { class_double(ThreeScaleToolbox::Entities::BackendUsage).as_stubbed_const }
      let(:backends) do
        3.times.map do |idx|
          instance_double(ThreeScaleToolbox::Entities::Backend, idx.to_s)
        end
      end
      let(:backend_usages) do
        backend_usage_attr_list.map do |bu_attrs|
          instance_double(ThreeScaleToolbox::Entities::BackendUsage, bu_attrs.fetch('id').to_s)
        end
      end
      let(:policy_chain_item) { double('policy_chain_item') }
      let(:policy_chain) { [policy_chain_item] }
      let(:proxy_data) { {} }
      let(:gateway_response) do
        {
          'error_status_auth_failed' => '1', 'error_headers_auth_failed' => '2',
          'error_auth_failed' => '3', 'error_status_auth_missing' => '4',
          'error_headers_auth_missing' => '5', 'error_auth_missing' => '6',
          'error_status_no_match' => '7', 'error_headers_no_match' => '8',
          'error_no_match' => '9', 'error_status_limits_exceeded' => '10',
          'error_headers_limits_exceeded' => '11', 'error_limits_exceeded' => '12'
        }
      end
      let(:oidc_data) do
        {
          'standard_flow_enabled' => false,
          'implicit_flow_enabled' => true,
          'service_accounts_enabled' => true,
          'direct_access_grants_enabled' => true
        }
      end
      let(:proxy_data) do
        {
          'auth_user_key' => 'my_key', 'credentials_location' => 'mycredentials',
          'hostname_rewrite' => 'my_hostname', 'secret_token' => 'my_secret_token',
          'auth_app_id' => 'my_app_id', 'auth_app_key' => 'my_app_key',
          'oidc_issuer_type' => 'my_oidc_issuer_type', 'oidc_issuer_endpoint' => 'my_oidc_endpoint',
          'jwt_claim_with_client_id' => 'my_jwt_client_id', 'jwt_claim_with_client_id_type' => 'my_jwt_type'
        }.merge(gateway_response)
      end
      subject { described_class.new(id: id, remote: remote, attrs: attrs).to_cr }

      before :each do
        plans.each_with_index do |plan, idx|
          allow(plan_class).to receive(:new).with(hash_including(id: idx+1)).and_return(plan)
          allow(plan).to receive(:id).and_return(idx+1)
          allow(plan).to receive(:system_name).and_return(plan_attr_list[idx].fetch('system_name'))
          allow(plan).to receive(:to_cr).and_return({})
        end

        backend_usages.each_with_index do |bu, idx|
          allow(backend_usage_class).to receive(:new).with(hash_including(id: idx+1)).and_return(bu)
          allow(bu).to receive(:backend).and_return(backends[idx])
          allow(bu).to receive(:to_cr).and_return({})
          allow(backends[idx]).to receive(:system_name).and_return("backend#{idx}")
        end

        allow(remote).to receive(:list_mapping_rules).and_return([])
        allow(remote).to receive(:list_metrics).and_return(metrics + methods)
        allow(remote).to receive(:list_methods).and_return(methods)
        allow(remote).to receive(:show_policies).and_return(policy_chain)
        allow(remote).to receive(:list_service_application_plans).and_return(plan_attr_list)
        allow(remote).to receive(:list_backend_usages).and_return(backend_usage_attr_list)
        allow(remote).to receive(:show_proxy).and_return(proxy_data)
      end

      it 'expected apiversion' do
        expect(subject).to include('apiVersion' => 'capabilities.3scale.net/v1beta1')
      end

      it 'expected kind' do
        expect(subject).to include('kind' => 'Product')
      end

      it 'expected name' do
        expect(subject.fetch('spec')).to include('name' => 'some name')
      end

      it 'expected systemName' do
        expect(subject.fetch('spec')).to include('systemName' => 'myservice')
      end

      it 'expected description' do
        expect(subject.fetch('spec')).to include('description' => 'some descr')
      end

      it 'mappingRules included' do
        expect(subject.fetch('spec')).to include('mappingRules' => [])
      end

      it 'metrics included' do
        expect(subject.fetch('spec').has_key? 'metrics').to be_truthy
        expect(subject.fetch('spec').fetch('metrics').keys).to match_array(metrics.map { |m|  m.fetch('system_name') })
      end

      it 'methods included' do
        expect(subject.fetch('spec').has_key? 'methods').to be_truthy
        expect(subject.fetch('spec').fetch('methods').keys).to match_array(methods.map { |m|  m.fetch('system_name') })
      end

      it 'policies included' do
        expect(subject.fetch('spec')).to include('policies' => policy_chain)
      end

      it 'applicationPlans included' do
        expect(subject.fetch('spec').has_key? 'applicationPlans').to be_truthy
        expect(subject.fetch('spec').fetch('applicationPlans').keys).to match_array(plans.map(&:system_name))
      end

      it 'backendUsages included' do
        expect(subject.fetch('spec').has_key? 'backendUsages').to be_truthy
        expect(subject.fetch('spec').fetch('backendUsages').keys).to match_array(backends.map(&:system_name))
      end

      it 'deployment included' do
        expect(subject.fetch('spec').has_key? 'deployment').to be_truthy
      end

      context 'deployment hosted' do
        let(:attrs) do
          {
            'id' => id, 'name' => 'some name', 'system_name' => 'myservice', 'description' => 'some descr',
            'deployment_option' => 'hosted', 'backend_version' => '1'
          }
        end
        let(:proxy_data) { {} }

        subject { described_class.new(id: id, remote: remote, attrs: attrs).to_cr.dig('spec', 'deployment') }

        it 'apicastHosted included' do
          expect(subject.has_key? 'apicastHosted').to be_truthy
        end

        it 'authentication included' do
          expect(subject.fetch('apicastHosted').has_key? 'authentication').to be_truthy
        end
      end

      context 'deployment self managed' do
        let(:attrs) do
          {
            'id' => id, 'name' => 'some name', 'system_name' => 'myservice', 'description' => 'some descr',
            'deployment_option' => 'self_managed', 'backend_version' => '1'
          }
        end
        let(:proxy_data) { { 'endpoint' => 'https://example.com', 'sandbox_endpoint' => 'https://staging.example.com' } }

        subject { described_class.new(id: id, remote: remote, attrs: attrs).to_cr.dig('spec', 'deployment') }

        it 'apicastSelfManaged included' do
          expect(subject.has_key? 'apicastSelfManaged').to be_truthy
        end

        it 'stagingPublicBaseURL included' do
          expect(subject.fetch('apicastSelfManaged')).to include('stagingPublicBaseURL' => 'https://staging.example.com')
        end

        it 'productionPublicBaseURL included' do
          expect(subject.fetch('apicastSelfManaged')).to include('productionPublicBaseURL' => 'https://example.com')
        end

        it 'authentication included' do
          expect(subject.fetch('apicastSelfManaged').has_key? 'authentication').to be_truthy
        end
      end

      context 'deployment unknown' do
        let(:attrs) do
          {
            'id' => id, 'name' => 'some name', 'system_name' => 'myservice', 'description' => 'some descr',
            'deployment_option' => 'unknown', 'backend_version' => '1'
          }
        end
        let(:proxy_data) { {} }

        subject { described_class.new(id: id, remote: remote, attrs: attrs).to_cr.dig('spec', 'deployment') }

        it 'apicastSelfManaged included' do
          expect { subject }.to raise_error(ThreeScaleToolbox::Error, /Unknown deployment option/)
        end
      end

      context 'authentication userkey' do
        let(:attrs) do
          {
            'id' => id, 'name' => 'some name', 'system_name' => 'myservice', 'description' => 'some descr',
            'deployment_option' => 'hosted', 'backend_version' => '1'
          }
        end

        let(:expected_gateway_response) do
          {
            'errorStatusAuthFailed' => gateway_response['error_status_auth_failed'],
            'errorHeadersAuthFailed' => gateway_response['error_headers_auth_failed'],
            'errorAuthFailed' => gateway_response['error_auth_failed'],
            'errorStatusAuthMissing' => gateway_response['error_status_auth_missing'],
            'errorHeadersAuthMissing' => gateway_response['error_headers_auth_missing'],
            'errorAuthMissing' => gateway_response['error_auth_missing'],
            'errorStatusNoMatch' => gateway_response['error_status_no_match'],
            'errorHeadersNoMatch' => gateway_response['error_headers_no_match'],
            'errorNoMatch' => gateway_response['error_no_match'],
            'errorStatusLimitsExceeded' => gateway_response['error_status_limits_exceeded'],
            'errorHeadersLimitsExceeded' => gateway_response['error_headers_limits_exceeded'],
            'errorLimitsExceeded' => gateway_response['error_limits_exceeded']
          }
        end

        subject { described_class.new(id: id, remote: remote, attrs: attrs).to_cr.dig('spec', 'deployment', 'apicastHosted', 'authentication') }

        it 'userkey included' do
          expect(subject.has_key? 'userkey').to be_truthy
        end

        it 'authUserKey included' do
          expect(subject.fetch('userkey')).to include('authUserKey' => 'my_key')
        end

        it 'credentials included' do
          expect(subject.fetch('userkey')).to include('credentials' => 'mycredentials')
        end

        it 'security included' do
          expect(subject.fetch('userkey')).to include('security' => { 'hostHeader' => 'my_hostname', 'secretToken' => 'my_secret_token' } )
        end

        it 'gateway response included' do
          expect(subject.fetch('userkey')).to include('gatewayResponse' => expected_gateway_response )
        end
      end

      context 'authentication appKeyAppID' do
        let(:attrs) do
          {
            'id' => id, 'name' => 'some name', 'system_name' => 'myservice', 'description' => 'some descr',
            'deployment_option' => 'hosted', 'backend_version' => '2'
          }
        end

        let(:expected_gateway_response) do
          {
            'errorStatusAuthFailed' => gateway_response['error_status_auth_failed'],
            'errorHeadersAuthFailed' => gateway_response['error_headers_auth_failed'],
            'errorAuthFailed' => gateway_response['error_auth_failed'],
            'errorStatusAuthMissing' => gateway_response['error_status_auth_missing'],
            'errorHeadersAuthMissing' => gateway_response['error_headers_auth_missing'],
            'errorAuthMissing' => gateway_response['error_auth_missing'],
            'errorStatusNoMatch' => gateway_response['error_status_no_match'],
            'errorHeadersNoMatch' => gateway_response['error_headers_no_match'],
            'errorNoMatch' => gateway_response['error_no_match'],
            'errorStatusLimitsExceeded' => gateway_response['error_status_limits_exceeded'],
            'errorHeadersLimitsExceeded' => gateway_response['error_headers_limits_exceeded'],
            'errorLimitsExceeded' => gateway_response['error_limits_exceeded']
          }
        end

        subject { described_class.new(id: id, remote: remote, attrs: attrs).to_cr.dig('spec', 'deployment', 'apicastHosted', 'authentication') }

        it 'appKeyAppID included' do
          expect(subject.has_key? 'appKeyAppID').to be_truthy
        end

        it 'appID included' do
          expect(subject.fetch('appKeyAppID')).to include('appID' => 'my_app_id')
        end

        it 'appKey included' do
          expect(subject.fetch('appKeyAppID')).to include('appKey' => 'my_app_key')
        end

        it 'credentials included' do
          expect(subject.fetch('appKeyAppID')).to include('credentials' => 'mycredentials')
        end

        it 'security included' do
          expect(subject.fetch('appKeyAppID')).to include('security' => { 'hostHeader' => 'my_hostname', 'secretToken' => 'my_secret_token' } )
        end

        it 'gateway response included' do
          expect(subject.fetch('appKeyAppID')).to include('gatewayResponse' => expected_gateway_response )
        end
      end

      context 'authentication oidc' do
        let(:attrs) do
          {
            'id' => id, 'name' => 'some name', 'system_name' => 'myservice', 'description' => 'some descr',
            'deployment_option' => 'hosted', 'backend_version' => 'oidc'
          }
        end

        let(:expected_oidc_flow) do
          {
            'standardFlowEnabled' => oidc_data['standard_flow_enabled'],
            'implicitFlowEnabled' => oidc_data['implicit_flow_enabled'],
            'serviceAccountsEnabled' => oidc_data['service_accounts_enabled'],
            'directAccessGrantsEnabled' => oidc_data['direct_access_grants_enabled']
          }
        end

        let(:expected_gateway_response) do
          {
            'errorStatusAuthFailed' => gateway_response['error_status_auth_failed'],
            'errorHeadersAuthFailed' => gateway_response['error_headers_auth_failed'],
            'errorAuthFailed' => gateway_response['error_auth_failed'],
            'errorStatusAuthMissing' => gateway_response['error_status_auth_missing'],
            'errorHeadersAuthMissing' => gateway_response['error_headers_auth_missing'],
            'errorAuthMissing' => gateway_response['error_auth_missing'],
            'errorStatusNoMatch' => gateway_response['error_status_no_match'],
            'errorHeadersNoMatch' => gateway_response['error_headers_no_match'],
            'errorNoMatch' => gateway_response['error_no_match'],
            'errorStatusLimitsExceeded' => gateway_response['error_status_limits_exceeded'],
            'errorHeadersLimitsExceeded' => gateway_response['error_headers_limits_exceeded'],
            'errorLimitsExceeded' => gateway_response['error_limits_exceeded']
          }
        end

        before :example do
          allow(remote).to receive(:show_oidc).and_return(oidc_data)
        end

        subject { described_class.new(id: id, remote: remote, attrs: attrs).to_cr.dig('spec', 'deployment', 'apicastHosted', 'authentication') }

        it 'oidc included' do
          expect(subject.has_key? 'oidc').to be_truthy
        end

        it 'issuerType included' do
          expect(subject.fetch('oidc')).to include('issuerType' => 'my_oidc_issuer_type')
        end

        it 'issuerEndpoint included' do
          expect(subject.fetch('oidc')).to include('issuerEndpoint' => 'my_oidc_endpoint')
        end

        it 'jwtClaimWithClientID included' do
          expect(subject.fetch('oidc')).to include('jwtClaimWithClientID' => 'my_jwt_client_id')
        end

        it 'jwtClaimWithClientIDType included' do
          expect(subject.fetch('oidc')).to include('jwtClaimWithClientIDType' => 'my_jwt_type')
        end

        it 'credentials included' do
          expect(subject.fetch('oidc')).to include('credentials' => 'mycredentials')
        end

        it 'security included' do
          expect(subject.fetch('oidc')).to include('security' => { 'hostHeader' => 'my_hostname', 'secretToken' => 'my_secret_token' } )
        end

        it 'gateway response included' do
          expect(subject.fetch('oidc')).to include('gatewayResponse' => expected_gateway_response )
        end

        it 'authenticationFlow included' do
          expect(subject.fetch('oidc')).to include('authenticationFlow' => expected_oidc_flow)
        end
      end
    end

    context '#find_metric_or_method' do
        before :example do
          allow(remote).to receive(:list_metrics).with(id).and_return(metrics + methods)
          allow(remote).to receive(:list_methods).with(id, 1).and_return(methods)
        end

        it 'existing metric is returned' do
          expect(subject.find_metric_or_method('metric_10').id).to eq(10)
        end

        it 'existing method is returned' do
          expect(subject.find_metric_or_method('method_101').id).to eq(101)
        end

        it 'non existing metric returns nil' do
          expect(subject.find_metric_or_method('unknown')).to be_nil
        end
    end
  end
end
