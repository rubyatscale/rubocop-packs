# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Packs::NamespaceConvention, :config do
  subject(:cop) { described_class.new(config) }
  let(:pack_name) { 'packs/apples' }
  let(:include_packs) { [pack_name] }
  let(:cop_config) do
    {
      'Enabled' => true,
      'IncludePacks' => include_packs,
      'GloballyPermittedNamespaces' => global_namespaces
    }
  end

  let(:global_namespaces) { [] }

  before do
    write_package_yml('packs/apples')
    write_package_yml('packs/tools')
    write_package_yml('packs/fruits/apples')
  end

  context 'unnested pack' do
    context 'globally permitted namespaces not configured' do
      context 'when file establishes different namespace' do
        let(:source) do
          <<~RUBY
            class Tool
            ^ Based on the filepath, this file defines `Tool`, but it should be namespaced as `Apples::Tool` with path `packs/apples/app/services/apples/tool.rb`.
            end
          RUBY
        end

        it { expect_offense source, Pathname.pwd.join(write_file('packs/apples/app/services/tool.rb')).to_s }
      end

      context 'when file is in different namespace' do
        let(:source) do
          <<~RUBY
            module Tools
            ^ Based on the filepath, this file defines `Tools::Blah`, but it should be namespaced as `Apples::Tools::Blah` with path `packs/apples/app/services/apples/tools/blah.rb`.
              class Blah
              end
            end
          RUBY
        end

        it { expect_offense source, Pathname.pwd.join(write_file('packs/apples/app/services/tools/blah.rb')).to_s }
      end

      context 'when file establishes primary namespace' do
        let(:source) do
          <<~RUBY
            module Apples
            end
          RUBY
        end

        it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/apples/app/services/apples.rb')).to_s }
      end

      context 'when file is in package namespace' do
        let(:source) do
          <<~RUBY
            module Apples
              class Tool
              end
            end
          RUBY
        end

        it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/apples/app/services/apples/tool.rb')).to_s }
      end
    end

    context 'several globally permitted namespaces are provided' do
      let(:global_namespaces) { %w[AppleTrees ApplePies Ciders] }

      context 'when file establishes different namespace' do
        let(:source) do
          <<~RUBY
            class Tool
            ^ Based on the filepath, this file defines `Tool`, but it should be namespaced as `Apples::Tool` with path `packs/apples/app/services/apples/tool.rb`.
            end
          RUBY
        end

        it { expect_offense source, Pathname.pwd.join(write_file('packs/apples/app/services/tool.rb')).to_s }
      end

      context 'when file is in different namespace' do
        let(:source) do
          <<~RUBY
            module Tools
            ^ Based on the filepath, this file defines `Tools::Blah`, but it should be namespaced as `Apples::Tools::Blah` with path `packs/apples/app/services/apples/tools/blah.rb`.
              class Blah
              end
            end
          RUBY
        end

        it { expect_offense source, Pathname.pwd.join(write_file('packs/apples/app/services/tools/blah.rb')).to_s }
      end

      context 'when file establishes primary namespace' do
        let(:source) do
          <<~RUBY
            module AppleTrees
            end
          RUBY
        end

        it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/apples/app/services/apple_trees.rb')).to_s }
      end

      context 'when file is in package namespace' do
        let(:source) do
          <<~RUBY
            module Ciders
              class Tool
              end
            end
          RUBY
        end

        it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/apples/app/services/ciders/tool.rb')).to_s }
      end
    end

    context 'file is a spec file' do
      let(:source) do
        <<~RUBY
          describe Forestry::Logging do
          end
        RUBY
      end

      it 'does not handle spec files and gracefully exits' do
        expect_no_offenses source, Pathname.pwd.join(write_file('packs/apples/spec/services/forestry/logging.rb')).to_s
      end
    end

    context 'when file is in different namespace and is in lib' do
      let(:source) do
        <<~RUBY
          module Tools
            class Blah
            end
          end
        RUBY
      end

      it 'does not handle spec files and gracefully exits' do
        expect_no_offenses source, Pathname.pwd.join(write_file('packs/apples/lib/services/tools/blah.rb')).to_s
      end
    end

    context 'when file establishes different namespace and is in concerns' do
      let(:source) do
        <<~RUBY
          class Tool
          ^ Based on the filepath, this file defines `Tool`, but it should be namespaced as `Apples::Tool` with path `packs/apples/app/models/concerns/apples/tool.rb`.
          end
        RUBY
      end

      it { expect_offense source, Pathname.pwd.join(write_file('packs/apples/app/models/concerns/tool.rb')).to_s }
    end

    context 'when file does not establish different namespace and is in concerns' do
      let(:source) do
        <<~RUBY
          class Apples
          end
        RUBY
      end

      it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/apples/app/models/concerns/apples.rb')).to_s }
    end

    context 'when the pack does not have namespace protection configured' do
      context 'when no other pack has namespace protection configured' do
        let(:include_packs) { [] }
        context 'when file is in different namespace' do
          let(:source) do
            <<~RUBY
              module Tools
                class Blah
                end
              end
            RUBY
          end

          it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/apples/app/services/tools/blah.rb')).to_s }
        end
      end

      context 'when another pack has namespace protection configured' do
        let(:include_packs) { ['packs/tools'] }

        context 'when file is in different namespace' do
          let(:source) do
            <<~RUBY
              module Tools
              ^ Based on the filepath, this file defines `Tools::Blah`. `packs/tools` prevents other packs from sitting in the `Tools` namespace. This should be namespaced under `Apples` with path `packs/apples/app/services/apples/tools/blah.rb`.
                class Blah
                end
              end
            RUBY
          end

          it { expect_offense source, Pathname.pwd.join(write_file('packs/apples/app/services/tools/blah.rb')).to_s }
        end
      end
    end
  end

  context 'nested pack' do
    let(:pack_name) { 'packs/fruits/apples' }

    context 'globally permitted namespaces not configured' do
      context 'when file establishes different namespace' do
        let(:source) do
          <<~RUBY
            class Tool
            ^ Based on the filepath, this file defines `Tool`, but it should be namespaced as `Apples::Tool` with path `packs/fruits/apples/app/services/apples/tool.rb`.
            end
          RUBY
        end

        it { expect_offense source, Pathname.pwd.join(write_file('packs/fruits/apples/app/services/tool.rb')).to_s }
      end

      context 'when file is in different namespace' do
        let(:source) do
          <<~RUBY
            module Tools
            ^ Based on the filepath, this file defines `Tools::Blah`, but it should be namespaced as `Apples::Tools::Blah` with path `packs/fruits/apples/app/services/apples/tools/blah.rb`.
              class Blah
              end
            end
          RUBY
        end

        it { expect_offense source, Pathname.pwd.join(write_file('packs/fruits/apples/app/services/tools/blah.rb')).to_s }
      end

      context 'when file establishes primary namespace' do
        let(:source) do
          <<~RUBY
            module Apples
            end
          RUBY
        end

        it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/fruits/apples/app/services/apples.rb')).to_s }
      end

      context 'when file is in package namespace' do
        let(:source) do
          <<~RUBY
            module Apples
              class Tool
              end
            end
          RUBY
        end

        it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/fruits/apples/app/services/apples/tool.rb')).to_s }
      end
    end

    context 'several globally permitted namespaces are configured' do
      let(:global_namespaces) { %w[AppleTrees ApplePies Ciders] }

      context 'when file establishes different namespace' do
        let(:source) do
          <<~RUBY
            class Tool
            ^ Based on the filepath, this file defines `Tool`, but it should be namespaced as `Apples::Tool` with path `packs/fruits/apples/app/services/apples/tool.rb`.
            end
          RUBY
        end

        it { expect_offense source, Pathname.pwd.join(write_file('packs/fruits/apples/app/services/tool.rb')).to_s }
      end

      context 'when file is in different namespace' do
        let(:source) do
          <<~RUBY
            module Tools
            ^ Based on the filepath, this file defines `Tools::Blah`, but it should be namespaced as `Apples::Tools::Blah` with path `packs/fruits/apples/app/services/apples/tools/blah.rb`.
              class Blah
              end
            end
          RUBY
        end

        it { expect_offense source, Pathname.pwd.join(write_file('packs/fruits/apples/app/services/tools/blah.rb')).to_s }
      end

      context 'when file establishes primary namespace' do
        let(:source) do
          <<~RUBY
            module AppleTrees
            end
          RUBY
        end

        it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/fruits/apples/app/services/apple_trees.rb')).to_s }
      end

      context 'when file is in package namespace' do
        let(:source) do
          <<~RUBY
            module Ciders
              class Tool
              end
            end
          RUBY
        end

        it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/fruits/apples/app/services/ciders/tool.rb')).to_s }
      end
    end

    context 'file is a spec file' do
      let(:source) do
        <<~RUBY
          describe Forestry::Logging do
          end
        RUBY
      end

      it 'does not handle spec files and gracefully exits' do
        expect_no_offenses source, Pathname.pwd.join(write_file('packs/fruits/apples/spec/services/forestry/logging.rb')).to_s
      end
    end

    context 'when file is in different namespace and is in lib' do
      let(:source) do
        <<~RUBY
          module Tools
            class Blah
            end
          end
        RUBY
      end

      it 'does not handle spec files and gracefully exits' do
        expect_no_offenses source, Pathname.pwd.join(write_file('packs/fruits/apples/lib/services/tools/blah.rb')).to_s
      end
    end

    context 'when file establishes different namespace and is in concerns' do
      let(:source) do
        <<~RUBY
          class Tool
          ^ Based on the filepath, this file defines `Tool`, but it should be namespaced as `Apples::Tool` with path `packs/fruits/apples/app/models/concerns/apples/tool.rb`.
          end
        RUBY
      end

      it { expect_offense source, Pathname.pwd.join(write_file('packs/fruits/apples/app/models/concerns/tool.rb')).to_s }
    end

    context 'when file does not establish different namespace and is in concerns' do
      let(:source) do
        <<~RUBY
          class Apples
          end
        RUBY
      end

      it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/fruits/apples/app/models/concerns/apples.rb')).to_s }
    end
  end
end
