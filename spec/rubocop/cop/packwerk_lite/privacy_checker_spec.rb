# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::PackwerkLite::Privacy, :config do
  subject(:cop) { described_class.new(config) }

  context 'namespace convention is being followed' do
    context 'a private API is used from a private folder' do
      before do
        write_package_yml('packs/apples', 'enforce_privacy' => true)
        write_file('packs/apples/app/services/apples.rb')
        write_package_yml('packs/tools', 'enforce_privacy' => true)
        write_file('packs/tools/app/services/tools.rb')
      end

      let(:source) do
        <<~RUBY
          class Apples
            Tools
            ^^^^^ Privacy violation detected. See https://github.com/Shopify/packwerk/blob/main/RESOLVING_VIOLATIONS.md for help
          end
        RUBY
      end

      it { expect_offense source, File.expand_path('packs/apples/app/services/apples.rb') }
    end

    context 'a private API is used from the public folder' do
      before do
        write_package_yml('packs/apples', 'enforce_privacy' => true)
        write_file('packs/apples/app/public/apples.rb')
        write_package_yml('packs/tools', 'enforce_privacy' => true)
        write_file('packs/tools/app/services/tools.rb')
      end

      let(:source) do
        <<~RUBY
          class Apples
            Tools
            ^^^^^ Privacy violation detected. See https://github.com/Shopify/packwerk/blob/main/RESOLVING_VIOLATIONS.md for help
          end
        RUBY
      end

      it { expect_offense source, File.expand_path('packs/apples/app/public/apples.rb') }
    end

    context 'a public API is used from a private folder' do
      before do
        write_package_yml('packs/apples', 'enforce_privacy' => true)
        write_file('packs/apples/app/public/apples.rb')
        write_package_yml('packs/tools', 'enforce_privacy' => true)
        write_file('packs/tools/app/public/tools.rb')
      end

      let(:source) do
        <<~RUBY
          class Apples
            Tools
          end
        RUBY
      end

      it { expect_no_offenses source, File.expand_path('packs/apples/app/public/apples.rb') }
    end
  end

  context 'namespace convention is not being followed' do
    context 'a private API is used from a private folder' do
      before do
        write_package_yml('packs/apples', 'enforce_privacy' => true)
        write_file('packs/apples/app/services/apples.rb')
        write_package_yml('packs/tools', 'enforce_privacy' => true)
        write_file('packs/tools/app/services/blah.rb')
      end

      let(:source) do
        <<~RUBY
          class Apples
            Blah
          end
        RUBY
      end

      it { expect_no_offenses source, File.expand_path('packs/apples/app/services/apples.rb') }
    end

    context 'a private API is used from the public folder' do
      before do
        write_package_yml('packs/apples', 'enforce_privacy' => true)
        write_file('packs/apples/app/public/apples.rb')
        write_package_yml('packs/tools', 'enforce_privacy' => true)
        write_file('packs/tools/app/services/blah.rb')
      end

      let(:source) do
        <<~RUBY
          class Apples
            Blah
          end
        RUBY
      end

      it { expect_no_offenses source, File.expand_path('packs/apples/app/public/apples.rb') }
    end

    context 'a public API is used from a private folder' do
      before do
        write_package_yml('packs/apples', 'enforce_privacy' => true)
        write_file('packs/apples/app/public/apples.rb')
        write_package_yml('packs/tools', 'enforce_privacy' => true)
        write_file('packs/tools/app/public/blah.rb')
      end

      let(:source) do
        <<~RUBY
          class Apples
            Blah
          end
        RUBY
      end

      it { expect_no_offenses source, File.expand_path('packs/apples/app/public/apples.rb') }
    end

    context 'packs share a sub-module namespace and do not fully qualify the constant' do
      before do
        write_package_yml('packs/apples', 'enforce_privacy' => true)
        write_file('packs/apples/app/public/apples.rb')
        write_file('packs/apples/app/public/apples/tools/pruners.rb')
        write_package_yml('packs/tools', 'enforce_privacy' => true)
        write_file('packs/tools/app/services/tools/pruners.rb')
      end

      let(:source) do
        <<~RUBY
          class Apples
            Tools::Pruners
            ^^^^^^^^^^^^^^ Privacy violation detected. See https://github.com/Shopify/packwerk/blob/main/RESOLVING_VIOLATIONS.md for help
          end
        RUBY
      end

      it 'produces a false positive' do
        expect_offense source, File.expand_path('packs/apples/app/public/apples.rb')
      end
    end

    context 'packs share a sub-module namespace and does fully qualify the constant' do
      before do
        write_package_yml('packs/apples', 'enforce_privacy' => true)
        write_file('packs/apples/app/public/apples.rb')
        write_file('packs/apples/app/public/apples/tools/pruners.rb')
        write_package_yml('packs/tools', 'enforce_privacy' => true)
        write_file('packs/tools/app/services/tools/pruners.rb')
      end

      let(:source) do
        <<~RUBY
          class Apples
            Apples::Tools::Pruners
          end
        RUBY
      end

      it 'does not produce a false positive' do
        expect_no_offenses source, File.expand_path('packs/apples/app/public/apples.rb')
      end
    end
  end
end
