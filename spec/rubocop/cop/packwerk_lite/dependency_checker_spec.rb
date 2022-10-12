# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::PackwerkLite::Dependency, :config do
  subject(:cop) { described_class.new(config) }

  context 'namespacing convention is being followed' do
    context 'unstated dependency used' do
      before do
        write_package_yml('packs/apples')
        write_package_yml('packs/tools')
        write_file('packs/apples/app/public/apples.rb')
        write_file('packs/tools/app/public/tool.rb')
      end

      let(:source) do
        <<~SOURCE
          class Tools
            Apples
            ^^^^^^ Dependency violation detected. See https://github.com/Shopify/packwerk/blob/main/RESOLVING_VIOLATIONS.md for help
          end
        SOURCE
      end

      it { expect_offense source, File.expand_path('packs/tools/app/public/tool.rb') }
    end

    context 'a partially qualified constant defined in same pack is use' do
      before do
        write_package_yml('packs/tools')
        write_file('packs/tools/app/services/tools/private.rb')
        write_file('packs/tools/app/public/tool.rb')
      end

      let(:source) do
        <<~SOURCE
          class Tools
            Private
          end
        SOURCE
      end

      it { expect_no_offenses source, File.expand_path('packs/tools/app/public/tool.rb') }
    end

    context 'a fully qualified constant defined in same pack is use' do
      before do
        write_package_yml('packs/tools')
        write_file('packs/tools/app/services/tools/private.rb')
        write_file('packs/tools/app/public/tool.rb')
      end

      let(:source) do
        <<~SOURCE
          class Tools
            Tools::Private
          end
        SOURCE
      end

      it { expect_no_offenses source, File.expand_path('packs/tools/app/public/tool.rb') }
    end

    context 'unstated dependency with multiple namespaces used' do
      before do
        write_package_yml('packs/apples')
        write_package_yml('packs/tools')
        write_file('packs/apples/app/services/apples/green.rb')
        write_file('packs/tools/app/public/tool.rb')
      end

      let(:source) do
        <<~SOURCE
          class Tools
            Apples::Green
            ^^^^^^^^^^^^^ Dependency violation detected. See https://github.com/Shopify/packwerk/blob/main/RESOLVING_VIOLATIONS.md for help
          end
        SOURCE
      end

      it { expect_offense source, File.expand_path('packs/tools/app/public/tool.rb') }
    end

    context 'stated dependency is used' do
      before do
        write_package_yml('packs/apples')
        write_package_yml('packs/tools', dependencies: ['packs/apples'])
        write_file('packs/apples/app/public/apples.rb')
        write_file('packs/tools/app/public/tool.rb')
      end

      let(:source) do
        <<~SOURCE
          class Tools
            Apples
          end
        SOURCE
      end

      it { expect_no_offenses source, File.expand_path('packs/tools/app/public/tool.rb') }
    end
  end

  context 'namespacing convention is not being followed' do
    context 'unstated dependency used' do
      before do
        write_package_yml('packs/apples')
        write_package_yml('packs/tools')
        write_file('packs/apples/app/public/public_api.rb')
        write_file('packs/tools/app/public/tool.rb')
      end

      let(:source) do
        <<~SOURCE
          class Tools
            PublicApi
          end
        SOURCE
      end

      it { expect_no_offenses source, File.expand_path('packs/tools/app/public/tool.rb') }
    end

    context 'a fully qualified constant defined in same pack is use' do
      before do
        write_package_yml('packs/tools')
        write_file('packs/tools/app/services/some_other_namespace/private.rb')
        write_file('packs/tools/app/public/tool.rb')
      end

      let(:source) do
        <<~SOURCE
          class Tools
            SomeOtherNamespace::Private
          end
        SOURCE
      end

      it { expect_no_offenses source, File.expand_path('packs/tools/app/public/tool.rb') }
    end

    context 'unstated dependency with multiple namespaces used' do
      before do
        write_package_yml('packs/apples')
        write_package_yml('packs/tools')
        write_file('packs/apples/app/services/blah/green.rb')
        write_file('packs/tools/app/public/tool.rb')
      end

      let(:source) do
        <<~SOURCE
          class Tools
            Blah::Green
          end
        SOURCE
      end

      it { expect_no_offenses source, File.expand_path('packs/tools/app/public/tool.rb') }
    end

    context 'stated dependency is used' do
      before do
        write_package_yml('packs/apples')
        write_package_yml('packs/tools', dependencies: ['packs/apples'])
        write_file('packs/apples/app/public/blah.rb')
        write_file('packs/tools/app/public/tool.rb')
      end

      let(:source) do
        <<~SOURCE
          class Tools
            Blah
          end
        SOURCE
      end

      it { expect_no_offenses source, File.expand_path('packs/tools/app/public/tool.rb') }
    end
  end
end
