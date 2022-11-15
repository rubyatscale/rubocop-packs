# typed: false

RSpec.describe RuboCop::Packs do
  before do
    RuboCop::Packs.bust_cache!
    RuboCop::Packs.configure do |config|
      config.permitted_pack_level_cops = ['Packs/RootNamespaceIsPackName', 'Packs/TypedPublicApi', 'Packs/ClassMethodsAsPublicApis']
    end
  end

  describe 'set_default_rubocop_yml' do
    before do
      write_package_yml('packs/my_pack')
      RuboCop::Packs.configure do |config|
        config.required_pack_level_cops = ['Style/SomeCop', 'Lint/SomeCop']
      end
    end

    let(:rubocop_yml) { ParsePackwerk.find('packs/my_pack').directory.join('package_rubocop.yml') }

    it 'generates a package_rubocop.yml with the right required pack level cops' do
      expect(rubocop_yml).to_not exist
      RuboCop::Packs.set_default_rubocop_yml(packs: ParsePackwerk.all)
      expect(rubocop_yml).to exist
      expect(YAML.load_file(rubocop_yml)).to eq({
                                                  'Style/SomeCop' => { 'Enabled' => true },
                                                  'Lint/SomeCop' => { 'Enabled' => true }
                                                })
    end

    it 'formats the package_rubocop.yml file nicely' do
      expect(rubocop_yml).to_not exist
      RuboCop::Packs.set_default_rubocop_yml(packs: ParsePackwerk.all)
      expect(rubocop_yml).to exist
      expect(rubocop_yml.read).to eq(<<~YML)
        Style/SomeCop:
          Enabled: true

        Lint/SomeCop:
          Enabled: true
      YML
    end
  end

  describe 'auto_generate_rubocop_todo' do
    let(:rubocop_todo_yml) { Pathname.new('packs/my_pack/package_rubocop_todo.yml') }

    before do
      write_package_yml('packs/my_pack')
      allow(RuboCop::Packs).to receive(:`).with('bundle exec rubocop  --only=Packs/RootNamespaceIsPackName,Packs/TypedPublicApi,Packs/ClassMethodsAsPublicApis --format=json').and_return(
        {
          'files' => [
            {
              'path' => 'packs/my_pack/path/to/file.rb',
              'offenses' => [{ 'cop_name' => 'Packs/RootNamespaceIsPackName' }, { 'cop_name' => 'Packs/ClassMethodsAsPublicApis' }]
            }
          ]
        }.to_json
      )
    end

    context 'pack has no current rubocop todo' do
      it 'creates the TODO' do
        expect(rubocop_todo_yml).to_not exist
        RuboCop::Packs.auto_generate_rubocop_todo(packs: [])
        expect(rubocop_todo_yml).to exist
        expect(YAML.load_file(rubocop_todo_yml)).to eq(
          {
            'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['packs/my_pack/path/to/file.rb'] },
            'Packs/ClassMethodsAsPublicApis' => { 'Exclude' => ['packs/my_pack/path/to/file.rb'] }
          }
        )
      end
    end

    context 'pack has an existing rubocop todo' do
      before do
        rubocop_todo_yml.write(
          YAML.dump(
            {
              'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['packs/my_pack/path/to/existing_file.rb'] },
              'Packs/TypedPublicApi' => { 'Exclude' => ['packs/my_pack/path/to/file.rb'] }
            }
          )
        )
      end

      it 'creates the TODO' do
        expect(rubocop_todo_yml).to exist
        RuboCop::Packs.auto_generate_rubocop_todo(packs: [])
        expect(rubocop_todo_yml).to exist
        expect(YAML.load_file(rubocop_todo_yml)).to eq(
          {
            'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['packs/my_pack/path/to/existing_file.rb', 'packs/my_pack/path/to/file.rb'] },
            'Packs/ClassMethodsAsPublicApis' => { 'Exclude' => ['packs/my_pack/path/to/file.rb'] },
            'Packs/TypedPublicApi' => { 'Exclude' => ['packs/my_pack/path/to/file.rb'] }
          }
        )
      end
    end
  end

  describe 'pack_based_rubocop_config' do
    let(:config) do
      write_file('config/default.yml', <<~YML.strip)
        <%= RuboCop::Packs.pack_based_rubocop_config(root_pathname: Pathname.pwd.to_s) %>
      YML
      YAML.safe_load(ERB.new(File.read('config/default.yml')).result(binding))
    end

    context 'no packs' do
      it 'returns an empty YAML hash' do
        expect(config).to eq({})
      end
    end

    context 'one pack with exclude' do
      before do
        write_package_yml('packs/some_pack')

        write_file('packs/some_pack/package_rubocop_todo.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Exclude:
              - 'packs/some_pack/app/services/bad_namespace.rb'
        YML
      end

      it 'returns the pack\'s exclude' do
        expect(config).to eq(
          {
            'Packs/RootNamespaceIsPackName' => {
              'Exclude' => [
                'packs/some_pack/app/services/bad_namespace.rb'
              ]
            }
          }
        )
      end
    end

    context 'two packs with exclude' do
      before do
        write_package_yml('packs/some_pack')

        write_file('packs/some_pack/package_rubocop_todo.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Exclude:
              - 'packs/some_pack/app/services/bad_namespace.rb'
        YML

        write_package_yml('packs/some_other_pack')

        write_file('packs/some_other_pack/package_rubocop_todo.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Exclude:
              - 'packs/some_other_pack/app/services/bad_namespace.rb'
        YML
      end

      it 'returns the pack\'s exclude' do
        expect(config.keys).to eq(['Packs/RootNamespaceIsPackName'])
        expect(config['Packs/RootNamespaceIsPackName'].keys).to eq(['Exclude'])
        expect(config['Packs/RootNamespaceIsPackName']['Exclude'].sort).to eq(['packs/some_other_pack/app/services/bad_namespace.rb', 'packs/some_pack/app/services/bad_namespace.rb'])
      end
    end

    context 'one pack with include' do
      before do
        write_package_yml('packs/some_pack')

        write_file('packs/some_pack/package_rubocop.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Enabled: true
        YML
      end

      it 'returns a config with the right packs in the include field' do
        expect(config).to eq(
          {
            'Packs/RootNamespaceIsPackName' => {
              'Include' => [
                'packs/some_pack/**/*'
              ]
            }
          }
        )
      end
    end

    context 'three packs with include' do
      before do
        write_package_yml('packs/some_pack')

        write_file('packs/some_pack/package_rubocop.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Enabled: false
        YML

        write_package_yml('packs/some_other_pack')

        write_file('packs/some_other_pack/package_rubocop.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Enabled: true
        YML

        write_package_yml('packs/yet_another_pack')

        write_file('packs/yet_another_pack/package_rubocop.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Enabled: true
        YML
      end

      it 'returns a config with the right packs in the include field' do
        expect(config.keys).to eq(['Packs/RootNamespaceIsPackName'])
        expect(config['Packs/RootNamespaceIsPackName'].keys).to eq(['Include'])
        expect(config['Packs/RootNamespaceIsPackName']['Include'].sort).to eq(['packs/some_other_pack/**/*', 'packs/yet_another_pack/**/*'])
      end
    end

    context 'packs with inclusions and exclusions' do
      before do
        write_package_yml('packs/some_pack')

        write_file('packs/some_pack/package_rubocop.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Enabled: false
        YML

        write_package_yml('packs/some_other_pack')

        write_file('packs/some_other_pack/package_rubocop.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Enabled: true
        YML

        write_file('packs/some_other_pack/package_rubocop_todo.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Exclude:
              - packs/some_other_pack/my_file.rb
        YML

        write_package_yml('packs/yet_another_pack')

        write_file('packs/yet_another_pack/package_rubocop.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Enabled: true
        YML

        write_file('packs/yet_another_pack/package_rubocop_todo.yml', <<~YML)
          Packs/RootNamespaceIsPackName:
            Exclude:
              - packs/yet_another_pack/my_file.rb
        YML
      end

      it 'correctly merges into a single rule specification' do
        expect(config.keys).to eq(['Packs/RootNamespaceIsPackName'])
        expect(config['Packs/RootNamespaceIsPackName'].keys.sort).to eq(%w[Exclude Include])
        expect(config['Packs/RootNamespaceIsPackName']['Include'].sort).to eq(['packs/some_other_pack/**/*', 'packs/yet_another_pack/**/*'])
        expect(config['Packs/RootNamespaceIsPackName']['Exclude'].sort).to eq(['packs/some_other_pack/my_file.rb', 'packs/yet_another_pack/my_file.rb'])
      end
    end
  end

  describe 'validations' do
    let(:errors) { RuboCop::Packs.validate }
    describe 'pack based package_rubocop_todo.yml files' do
      context 'no packs' do
        it 'returns an empty list' do
          expect(errors).to be_empty
        end
      end

      context 'one pack with valid exclude' do
        before do
          write_package_yml('packs/some_pack')

          write_file('packs/some_pack/app/services/bad_namespace.rb', '')

          write_file('packs/some_pack/package_rubocop_todo.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              Exclude:
                - 'packs/some_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an empty list' do
          expect(errors).to be_empty
        end
      end

      context 'one pack with valid exclude where file does not exist' do
        before do
          write_package_yml('packs/some_pack')

          write_file('packs/some_pack/package_rubocop_todo.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              Exclude:
                - 'packs/some_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an empty list' do
          expect(errors).to be_empty
        end
      end

      context 'one pack with disallowed cop key' do
        before do
          write_package_yml('packs/some_pack')
          write_file('packs/some_pack/package_rubocop_todo.yml', <<~YML)
            SomeOtherCop:
              Exclude:
                - 'packs/some_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/package_rubocop_todo.yml contains invalid configuration for SomeOtherCop.
            Please only configure the following cops on a per-pack basis: ["Packs/RootNamespaceIsPackName", "Packs/TypedPublicApi", "Packs/ClassMethodsAsPublicApis"]"
            For ignoring other cops, please instead modify the top-level package_rubocop_todo.yml file.
          ERROR
          expect(errors).to eq([error])
        end
      end

      context 'one pack with disallowed configuration key' do
        before do
          write_package_yml('packs/some_pack')
          write_file('packs/some_pack/package_rubocop_todo.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              SomethingElse:
                - 'packs/some_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/package_rubocop_todo.yml contains invalid configuration for Packs/RootNamespaceIsPackName.
            Please ensure the only configuration for Packs/RootNamespaceIsPackName is `Exclude`
          ERROR
          expect(errors).to eq([error])
        end
      end

      context 'one pack with filepath from the wrong pack' do
        before do
          write_package_yml('packs/some_pack')

          write_package_yml('packs/some_other_pack')

          write_file('packs/some_pack/package_rubocop_todo.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              Exclude:
                - 'packs/some_other_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/package_rubocop_todo.yml contains invalid configuration for Packs/RootNamespaceIsPackName.
            packs/some_other_pack/app/services/bad_namespace.rb does not belong to packs/some_pack. Please ensure you only add exclusions
            for files within this pack.
          ERROR

          expect(errors).to eq([error])
        end
      end

      context 'one pack with inherit_from set' do
        before do
          write_package_yml('packs/some_pack')

          write_file('packs/some_pack/package_rubocop.yml', <<~YML)
            inherit_from: "something_else.yml"
          YML
        end

        it 'has an error' do
          error = <<~ERROR
            packs/some_pack/package_rubocop.yml contains invalid configuration for inherit_from.
            Please only configure the following cops on a per-pack basis: ["Packs/RootNamespaceIsPackName", "Packs/TypedPublicApi", "Packs/ClassMethodsAsPublicApis"]"
            For ignoring other cops, please instead modify the top-level .rubocop.yml file.
          ERROR

          expect(errors).to eq([error])
        end
      end
    end

    describe 'pack based package_rubocop.yml files' do
      context 'no packs' do
        it 'returns an empty list' do
          expect(errors).to be_empty
        end
      end

      context 'one pack with valid package_rubocop.yml' do
        before do
          write_package_yml('packs/some_pack')
          write_file('packs/some_pack/package_rubocop.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              Enabled: true
          YML
        end

        it 'returns an empty list' do
          expect(errors).to be_empty
        end
      end

      context 'one pack with valid package_rubocop.yml with FailureMode specified' do
        before do
          write_package_yml('packs/some_pack')
          write_file('packs/some_pack/package_rubocop.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              Enabled: true
              FailureMode: strict
          YML
        end

        it 'returns an empty list' do
          expect(errors).to be_empty
        end
      end

      context 'one pack with disallowed cop key' do
        before do
          write_package_yml('packs/some_pack')
          write_file('packs/some_pack/package_rubocop.yml', <<~YML)
            SomeOtherCop:
              Enabled: true
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/package_rubocop.yml contains invalid configuration for SomeOtherCop.
            Please only configure the following cops on a per-pack basis: ["Packs/RootNamespaceIsPackName", "Packs/TypedPublicApi", "Packs/ClassMethodsAsPublicApis"]"
            For ignoring other cops, please instead modify the top-level .rubocop.yml file.
          ERROR
          expect(errors).to eq([error])
        end
      end

      context 'one pack with disallowed configuration key' do
        before do
          write_package_yml('packs/some_pack')
          write_file('packs/some_pack/package_rubocop.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              Exclude:
                - 'packs/some_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/package_rubocop.yml contains invalid configuration for Packs/RootNamespaceIsPackName.
            Please ensure the only configuration for Packs/RootNamespaceIsPackName is `Enabled` and `FailureMode`
          ERROR
          expect(errors).to eq([error])
        end
      end

      context 'one pack with unspecified cops' do
        before do
          RuboCop::Packs.configure do |config|
            config.required_pack_level_cops = ['Packs/RootNamespaceIsPackName', 'Packs/TypedPublicApi']
          end
        end

        before do
          write_package_yml('packs/some_pack')
          write_file('packs/some_pack/package_rubocop.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              Enabled: true
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/package_rubocop.yml is missing configuration for Packs/TypedPublicApi.
          ERROR
          expect(errors).to eq([error])
        end
      end

      # For now, this is allowed. We might add this restriction back once we've completed the migration off of `package_protections`
      context 'one pack without a package_rubocop.yml' do
        before do
          write_package_yml('packs/some_pack')
        end

        it 'returns no errors' do
          expect(errors).to eq([])
        end
      end
    end

    describe 'FailureMode: strict' do
      context 'package has specified FailureMode: strict for a cop' do
        context 'package has pack-based package_rubocop_todo.yml entries for that cop' do
          before do
            write_package_yml('packs/some_pack')

            write_file('packs/some_pack/app/services/some_file.rb', '')

            write_file('packs/some_pack/package_rubocop.yml', <<~YML)
              Packs/RootNamespaceIsPackName:
                Enabled: true
                FailureMode: strict
            YML

            write_file('packs/some_pack/package_rubocop_todo.yml', <<~YML)
              Packs/RootNamespaceIsPackName:
                Exclude:
                  - 'packs/some_pack/app/services/some_file.rb'
            YML
          end

          it 'returns an empty list' do
            expect(errors).to eq([
                                   'packs/some_pack has set `Packs/RootNamespaceIsPackName` to `FailureMode: strict` in `packs/some_pack/package_rubocop.yml`, forbidding new exceptions. Please either remove `packs/some_pack/app/services/some_file.rb` from the top-level and pack-specific `package_rubocop_todo.yml` files or remove `FailureMode: strict`.'
                                 ])
          end
        end

        context 'package has top-level package_rubocop_todo.yml entries for that cop' do
          before do
            write_package_yml('packs/some_pack')

            write_file('packs/some_pack/app/services/some_file.rb', '')

            write_file('packs/some_pack/package_rubocop.yml', <<~YML)
              Packs/RootNamespaceIsPackName:
                Enabled: true
                FailureMode: strict
            YML

            write_file('package_rubocop_todo.yml', <<~YML)
              Packs/RootNamespaceIsPackName:
                Exclude:
                  - 'packs/some_pack/app/services/some_file.rb'
            YML
          end

          it 'returns an empty list' do
            expect(errors).to eq([
                                   'packs/some_pack has set `Packs/RootNamespaceIsPackName` to `FailureMode: strict` in `packs/some_pack/package_rubocop.yml`, forbidding new exceptions. Please either remove `packs/some_pack/app/services/some_file.rb` from the top-level and pack-specific `package_rubocop_todo.yml` files or remove `FailureMode: strict`.'
                                 ])
          end
        end
      end
    end
  end
end
