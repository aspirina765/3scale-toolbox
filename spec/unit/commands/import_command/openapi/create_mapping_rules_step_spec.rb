RSpec.describe ThreeScaleToolbox::Commands::ImportCommand::OpenAPI::CreateMappingRulesStep do
  let(:service) { instance_double('ThreeScaleToolbox::Entities::Service') }
  let(:mappingrule_class) { class_double(ThreeScaleToolbox::Entities::MappingRule).as_stubbed_const }
  let(:op0) { double('op0') }
  let(:op1) { double('op1') }
  let(:operations) { [op0, op1] }
  let(:openapi_context) do
    {
      operations: operations,
      target: service,
      logger: logger,
    }
  end
  let(:mapping_rule_0) { double('mapping_rule_0') }
  let(:mapping_rule_1) { double('mapping_rule_1') }
  let(:logger) { Logger.new(File::NULL) }
  subject { described_class.new(openapi_context) }

  context '#call' do
    before :each do
      allow(op0).to receive(:mapping_rule).and_return(mapping_rule_0)
      allow(op0).to receive(:http_method).and_return('http_method_0')
      allow(op0).to receive(:pattern).and_return('pattern_0')
      allow(op0).to receive(:friendly_name).and_return('op0')

      allow(op1).to receive(:mapping_rule).and_return(mapping_rule_1)
      allow(op1).to receive(:http_method).and_return('http_method_1')
      allow(op1).to receive(:pattern).and_return('pattern_1')
      allow(op1).to receive(:friendly_name).and_return('op1')
      expect(mappingrule_class).to receive(:create).with(service: service,
                                                        attrs: mapping_rule_0)
      expect(mappingrule_class).to receive(:create).with(service: service,
                                                        attrs: mapping_rule_1)
    end

    it 'mapping rules created' do
      subject.call
    end
  end
end
