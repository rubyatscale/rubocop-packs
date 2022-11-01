# typed: false

RSpec.describe RuboCop::Packs do
  before do
    RuboCop::Packs.bust_cache!
    RuboCop::Packs.configure do |config|
      config.permitted_pack_level_cops = ['Packs/NamespaceConvention', 'Packs/TypedPublicApi', 'Packs/ClassMethodsAsPublicApis']
    end
  end

  describe 'auto_generate_rubocop_todo' do
    let(:rubocop_todo_yml) { Pathname.new('packs/my_pack/.rubocop_todo.yml') }

    before do
      write_package_yml('packs/my_pack')
      allow(RuboCop::Packs).to receive(:`).with('bundle exec rubocop  --only=Packs/NamespaceConvention,Packs/TypedPublicApi,Packs/ClassMethodsAsPublicApis --format=json').and_return(
        {
          'files' => [
            {
              'path' => 'packs/my_pack/path/to/file.rb',
              'offenses' => [{ 'cop_name' => 'Packs/NamespaceConvention' }, { 'cop_name' => 'Packs/ClassMethodsAsPublicApis' }]
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
            'Packs/NamespaceConvention' => { 'Exclude' => ['packs/my_pack/path/to/file.rb'] },
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
              'Packs/NamespaceConvention' => { 'Exclude' => ['packs/my_pack/path/to/existing_file.rb'] },
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
            'Packs/NamespaceConvention' => { 'Exclude' => ['packs/my_pack/path/to/existing_file.rb', 'packs/my_pack/path/to/file.rb'] },
            'Packs/ClassMethodsAsPublicApis' => { 'Exclude' => ['packs/my_pack/path/to/file.rb'] },
            'Packs/TypedPublicApi' => { 'Exclude' => ['packs/my_pack/path/to/file.rb'] }
          }
        )
      end
    end
  end

  describe 'pack_based_rubocop_todos' do
    let(:config) do
      write_file('config/default.yml', <<~YML.strip)
        <%= RuboCop::Packs.pack_based_rubocop_todos(root_pathname: Pathname.pwd.to_s) %>
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

        write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
          Packs/NamespaceConvention:
            Exclude:
              - 'packs/some_pack/app/services/bad_namespace.rb'
        YML
      end

      it 'returns the pack\'s exclude' do
        expect(config).to eq(
          {
            'Packs/NamespaceConvention' => {
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

        write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
          Packs/NamespaceConvention:
            Exclude:
              - 'packs/some_pack/app/services/bad_namespace.rb'
        YML

        write_package_yml('packs/some_other_pack')

        write_file('packs/some_other_pack/.rubocop_todo.yml', <<~YML)
          Packs/NamespaceConvention:
            Exclude:
              - 'packs/some_other_pack/app/services/bad_namespace.rb'
        YML
      end

      it 'returns the pack\'s exclude' do
        expect(config.keys).to eq(['Packs/NamespaceConvention'])
        expect(config['Packs/NamespaceConvention'].keys).to eq(['Exclude'])
        expect(config['Packs/NamespaceConvention']['Exclude'].sort).to eq(['packs/some_other_pack/app/services/bad_namespace.rb', 'packs/some_pack/app/services/bad_namespace.rb'])
      end
    end
  end

  describe 'validations' do
    let(:errors) { RuboCop::Packs.validate }
    describe 'pack based .rubocop_todo.yml files' do
      context 'no packs' do
        it 'returns an empty list' do
          expect(errors).to be_empty
        end
      end

      context 'one pack with valid exclude' do
        before do
          write_package_yml('packs/some_pack')

          write_file('packs/some_pack/app/services/bad_namespace.rb', '')

          write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
            Packs/NamespaceConvention:
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

          write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
            Packs/NamespaceConvention:
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
          write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
            SomeOtherCop:
              Exclude:
                - 'packs/some_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/.rubocop_todo.yml contains invalid configuration for SomeOtherCop.
            Please only configure the following cops on a per-pack basis: ["Packs/NamespaceConvention", "Packs/TypedPublicApi", "Packs/ClassMethodsAsPublicApis"]"
            For ignoring other cops, please instead modify the top-level .rubocop_todo.yml file.
          ERROR
          expect(errors).to eq([error])
        end
      end

      context 'one pack with disallowed configuration key' do
        before do
          write_package_yml('packs/some_pack')
          write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
            Packs/NamespaceConvention:
              SomethingElse:
                - 'packs/some_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/.rubocop_todo.yml contains invalid configuration for Packs/NamespaceConvention.
            Please ensure the only configuration for Packs/NamespaceConvention is `Exclude`
          ERROR
          expect(errors).to eq([error])
        end
      end

      context 'one pack with filepath from the wrong pack' do
        before do
          write_package_yml('packs/some_pack')

          write_package_yml('packs/some_other_pack')

          write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
            Packs/NamespaceConvention:
              Exclude:
                - 'packs/some_other_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/.rubocop_todo.yml contains invalid configuration for Packs/NamespaceConvention.
            packs/some_other_pack/app/services/bad_namespace.rb does not belong to packs/some_pack. Please ensure you only add exclusions
            for files within this pack.
          ERROR

          expect(errors).to eq([error])
        end
      end
    end

    describe 'pack based .rubocop.yml files' do
      context 'no packs' do
        it 'returns an empty list' do
          expect(errors).to be_empty
        end
      end

      context 'one pack with valid .rubocop.yml' do
        before do
          write_package_yml('packs/some_pack')
          write_file('packs/some_pack/.rubocop.yml', <<~YML)
            Packs/NamespaceConvention:
              Enabled: true
          YML
        end

        it 'returns an empty list' do
          expect(errors).to be_empty
        end
      end

      context 'one pack with valid .rubocop.yml with FailureMode specified' do
        before do
          write_package_yml('packs/some_pack')
          write_file('packs/some_pack/.rubocop.yml', <<~YML)
            Packs/NamespaceConvention:
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
          write_file('packs/some_pack/.rubocop.yml', <<~YML)
            SomeOtherCop:
              Enabled: true
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/.rubocop.yml contains invalid configuration for SomeOtherCop.
            Please only configure the following cops on a per-pack basis: ["Packs/NamespaceConvention", "Packs/TypedPublicApi", "Packs/ClassMethodsAsPublicApis"]"
            For ignoring other cops, please instead modify the top-level .rubocop.yml file.
          ERROR
          expect(errors).to eq([error])
        end
      end

      context 'one pack with disallowed configuration key' do
        before do
          write_package_yml('packs/some_pack')
          write_file('packs/some_pack/.rubocop.yml', <<~YML)
            Packs/NamespaceConvention:
              Exclude:
                - 'packs/some_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/.rubocop.yml contains invalid configuration for Packs/NamespaceConvention.
            Please ensure the only configuration for Packs/NamespaceConvention is `Enabled` and `FailureMode`
          ERROR
          expect(errors).to eq([error])
        end
      end
    end
  end

  describe 'exclude_for_rule' do
    it 'finds the right exclusions' do
      write_file('.rubocop_todo.yml', <<~YML)
        Packs/NamespaceConvention:
          Exclude:
            - app/services/foo.rb
        Packs/TypedPublicApi:
          Exclude:
            - app/services/foo.rb
      YML

      write_file('packs/my_pack/.rubocop_todo.yml', <<~YML)
        Packs/TypedPublicApi:
          Exclude:
            - packs/my_pack/app/services/foo.rb
      YML

      expect(RuboCop::Packs.exclude_for_rule('Packs/NamespaceConvention')).to eq(Set.new([
                                                                                           'app/services/foo.rb'
                                                                                         ]))

      expect(RuboCop::Packs.exclude_for_rule('Packs/TypedPublicApi')).to eq(Set.new([
                                                                                      'app/services/foo.rb',
                                                                                      'packs/my_pack/app/services/foo.rb'
                                                                                    ]))
    end
  end
end
