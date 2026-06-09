# typed: false
# frozen_string_literal: true

# Unit specs for the private DesiredZeitwerkApi helper. The cop only invokes it
# for `app/` paths, but the helper also supports `lib/` for API generality, so
# we exercise it directly here (imagine a not-yet-zeitwerk-compliant codebase).
RSpec.describe RuboCop::Cop::Packs::RootNamespaceIsPackName.const_get(:DesiredZeitwerkApi) do # rubocop:disable Sorbet/ConstantsFromStrings
  subject(:api) { described_class.new }

  before { write_pack('packs/apples') }

  let(:pack) { Packs.find('packs/apples') }

  context 'when the file lives under app/' do
    it 'computes an app-based namespace context' do
      context = api.for_file('packs/apples/app/services/tool.rb', pack)

      expect(context.expected_namespace).to eq('Apples')
      expect(context.expected_filepath).to eq('packs/apples/app/services/apples/tool.rb')
    end
  end

  context 'when the file lives under lib/' do
    it 'computes a lib-based namespace context' do
      context = api.for_file('packs/apples/lib/tool.rb', pack)

      expect(context.expected_filepath).to include('packs/apples/lib/')
    end
  end

  context 'when the file is in neither app/ nor lib/' do
    it 'raises because the autoload folder cannot be determined' do
      expect { api.for_file('packs/apples/tool.rb', pack) }.to raise_error(TypeError)
    end
  end
end
