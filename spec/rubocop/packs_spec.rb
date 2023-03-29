# typed: false

RSpec.describe RuboCop::Packs do
  before do
    RuboCop::Packs.bust_cache!
    RuboCop::Packs.configure do |config|
      config.permitted_pack_level_cops = ['Packs/RootNamespaceIsPackName', 'Packs/TypedPublicApis', 'Packs/ClassMethodsAsPublicApis']
    end
  end

  describe 'set_default_rubocop_yml' do
    before do
      write_pack('packs/my_pack')
      RuboCop::Packs.configure do |config|
        config.required_pack_level_cops = ['Style/SomeCop', 'Lint/SomeCop']
      end
    end

    let(:rubocop_yml) { Packs.find('packs/my_pack').relative_path.join('.rubocop.yml') }

    it 'generates a .rubocop.yml with the right required pack level cops' do
      expect(rubocop_yml).to_not exist
      RuboCop::Packs.set_default_rubocop_yml(packs: Packs.all)
      expect(rubocop_yml).to exist
      expect(YAML.load_file(rubocop_yml)).to eq({
                                                  'Style/SomeCop' => { 'Enabled' => true },
                                                  'Lint/SomeCop' => { 'Enabled' => true }
                                                })
    end

    it 'formats the .rubocop.yml file nicely' do
      expect(rubocop_yml).to_not exist
      RuboCop::Packs.set_default_rubocop_yml(packs: Packs.all)
      expect(rubocop_yml).to exist
      expect(rubocop_yml.read).to eq(<<~YML)
        Style/SomeCop:
          Enabled: true

        Lint/SomeCop:
          Enabled: true
      YML
    end
  end

  describe 'regenerate_todo' do
    let(:rubocop_todo_yml) { Pathname.new('packs/my_pack/.rubocop_todo.yml') }

    let(:cop_cli_args) do
      '--only=Packs/RootNamespaceIsPackName,Packs/TypedPublicApis,Packs/ClassMethodsAsPublicApis'
    end
    let(:offenses) do
      [{ 'cop_name' => 'Packs/RootNamespaceIsPackName' }, { 'cop_name' => 'Packs/ClassMethodsAsPublicApis' }]
    end

    before do
      write_file('.rubocop.yml', <<~YML)
        Packs/ClassMethodsAsPublicApis:
          Enabled: true
        Packs/RootNamespaceIsPackName:
          Enabled: true
        Packs/TypedPublicApis:
          Enabled: true
      YML
      write_pack('packs/my_pack')
      rubocop_json = { 'files' => [{ 'path' => 'packs/my_pack/path/to/file.rb', 'offenses' => offenses }] }.to_json
      allow_any_instance_of(RuboCop::CLI).to receive(:run).with(['packs/my_pack', cop_cli_args, '--format=json', '--out=tmp/rubocop-output']) do
        Pathname.new('tmp/rubocop-output').write(rubocop_json)
      end

      allow_any_instance_of(RuboCop::CLI).to receive(:run).with(['packs/my_pack/path/to/file.rb', cop_cli_args, '--format=json', '--out=tmp/rubocop-output']) do
        Pathname.new('tmp/rubocop-output').write(rubocop_json)
      end
    end

    context 'regenerating TODO for entire packs' do
      context 'pack has no current rubocop todo' do
        before { write_file('packs/my_pack/.rubocop.yml') }

        it 'creates the TODO' do
          expect(rubocop_todo_yml).to_not exist
          RuboCop::Packs.regenerate_todo(packs: [Packs.find('packs/my_pack')])
          expect(rubocop_todo_yml).to exist
          expect(YAML.load_file(rubocop_todo_yml)).to eq(
            {
              'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/file.rb'] },
              'Packs/ClassMethodsAsPublicApis' => { 'Exclude' => ['path/to/file.rb'] }
            }
          )
        end
      end

      context 'pack does not use pack-based rubocop' do
        it 'does not create the TODO' do
          expect(rubocop_todo_yml).to_not exist
          RuboCop::Packs.regenerate_todo(packs: [Packs.find('packs/my_pack')])
          expect(rubocop_todo_yml).to_not exist
        end
      end

      context 'pack has an existing rubocop todo' do
        before do
          write_file('packs/my_pack/.rubocop.yml')
          rubocop_todo_yml.write(
            YAML.dump(
              {
                'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/existing_file.rb'] },
                'Packs/TypedPublicApis' => { 'Exclude' => ['path/to/file.rb'] }
              }
            )
          )
        end

        it 'recreates the TODO from scratch' do
          expect(rubocop_todo_yml).to exist
          RuboCop::Packs.regenerate_todo(packs: [Packs.find('packs/my_pack')])
          expect(rubocop_todo_yml).to exist
          expect(YAML.load_file(rubocop_todo_yml)).to eq(
            {
              'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/file.rb'] },
              'Packs/ClassMethodsAsPublicApis' => { 'Exclude' => ['path/to/file.rb'] }
            }
          )
        end
      end

      # This can happen because a cop can fail on multiple lines in the same file
      context 'pack has multiple offenses for the same file' do
        before { write_file('packs/my_pack/.rubocop.yml') }

        let(:offenses) do
          [{ 'cop_name' => 'Packs/RootNamespaceIsPackName' }, { 'cop_name' => 'Packs/ClassMethodsAsPublicApis' }, { 'cop_name' => 'Packs/ClassMethodsAsPublicApis' }, { 'cop_name' => 'Packs/ClassMethodsAsPublicApis' }]
        end

        it 'does not list the same TODO multiple times' do
          RuboCop::Packs.regenerate_todo(packs: [Packs.find('packs/my_pack')])
          expect(rubocop_todo_yml).to exist
          expect(YAML.load_file(rubocop_todo_yml)).to eq(
            {
              'Packs/ClassMethodsAsPublicApis' => { 'Exclude' => ['path/to/file.rb'] },
              'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/file.rb'] }
            }
          )
        end
      end

      context 'pack has offenses for a cop that is explicitly globally off' do
        before do
          write_file('.rubocop.yml', <<~YML)
            Packs/ClassMethodsAsPublicApis:
              Enabled: false
            Packs/RootNamespaceIsPackName:
              Enabled: true
          YML
          write_file('packs/my_pack/.rubocop.yml')
        end

        let(:offenses) do
          [{ 'cop_name' => 'Packs/RootNamespaceIsPackName' }]
        end

        let(:cop_cli_args) { '--only=Packs/RootNamespaceIsPackName' }

        it 'does not list the same TODO multiple times' do
          RuboCop::Packs.regenerate_todo(packs: [Packs.find('packs/my_pack')])
          expect(rubocop_todo_yml).to exist
          expect(YAML.load_file(rubocop_todo_yml)).to eq(
            {
              'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/file.rb'] }
            }
          )
        end
      end

      context 'pack has offenses for a cop that is implicitly globally off' do
        before do
          write_file('.rubocop.yml', <<~YML)
            Style/SomeOtherCop:
              Enabled: true
            Packs/RootNamespaceIsPackName:
              Enabled: true
          YML
          write_file('packs/my_pack/.rubocop.yml')
        end

        let(:cop_cli_args) { '--only=Packs/RootNamespaceIsPackName' }
        let(:offenses) do
          [{ 'cop_name' => 'Packs/RootNamespaceIsPackName' }, { 'cop_name' => 'Packs/ClassMethodsAsPublicApis' }, { 'cop_name' => 'Packs/ClassMethodsAsPublicApis' }, { 'cop_name' => 'Packs/ClassMethodsAsPublicApis' }]
        end

        it 'does not list the same TODO multiple times' do
          RuboCop::Packs.regenerate_todo(packs: [Packs.find('packs/my_pack')])
          expect(rubocop_todo_yml).to exist
          expect(YAML.load_file(rubocop_todo_yml)).to eq(
            {
              'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/file.rb'] },
              'Packs/ClassMethodsAsPublicApis' => { 'Exclude' => ['path/to/file.rb'] }
            }
          )
        end
      end
    end

    context 'regenerating TODO for one file' do
      context 'pack has no current rubocop todo' do
        before { write_file('packs/my_pack/.rubocop.yml') }

        it 'creates the TODO' do
          expect(rubocop_todo_yml).to_not exist
          RuboCop::Packs.regenerate_todo(files: ['packs/my_pack/path/to/file.rb'])
          expect(rubocop_todo_yml).to exist
          expect(YAML.load_file(rubocop_todo_yml)).to eq(
            {
              'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/file.rb'] },
              'Packs/ClassMethodsAsPublicApis' => { 'Exclude' => ['path/to/file.rb'] }
            }
          )
        end
      end

      context 'pack does not use pack-based rubocop' do
        it 'does not create the TODO' do
          expect(rubocop_todo_yml).to_not exist
          RuboCop::Packs.regenerate_todo(files: ['packs/my_pack/path/to/file.rb'])
          expect(rubocop_todo_yml).to_not exist
        end
      end

      context 'pack has an existing rubocop todo' do
        before do
          rubocop_todo_yml.write(
            YAML.dump(
              {
                'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/existing_file.rb'] },
                'Packs/TypedPublicApis' => { 'Exclude' => ['path/to/file.rb'] }
              }
            )
          )
          write_file('packs/my_pack/.rubocop.yml')
        end

        it 'adds to the TODO with the new files' do
          expect(rubocop_todo_yml).to exist
          RuboCop::Packs.regenerate_todo(files: ['packs/my_pack/path/to/file.rb'])
          expect(rubocop_todo_yml).to exist
          expect(YAML.load_file(rubocop_todo_yml)).to eq(
            {
              'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/existing_file.rb', 'path/to/file.rb'] },
              'Packs/TypedPublicApis' => { 'Exclude' => ['path/to/file.rb'] },
              'Packs/ClassMethodsAsPublicApis' => { 'Exclude' => ['path/to/file.rb'] }
            }
          )
        end
      end
    end

    context 'regenerating TODO for multiple files' do
      before do
        rubocop_json = {
          'files' => [
            {
              'path' => 'packs/my_pack/path/to/file.rb',
              'offenses' => [{ 'cop_name' => 'Packs/RootNamespaceIsPackName' }, { 'cop_name' => 'Packs/ClassMethodsAsPublicApis' }]
            }
          ]
        }.to_json

        allow_any_instance_of(RuboCop::CLI).to receive(:run).with(['packs/my_pack/path/to/file.rb', 'packs/my_pack/path/to/other_file.rb', '--only=Packs/RootNamespaceIsPackName,Packs/TypedPublicApis,Packs/ClassMethodsAsPublicApis', '--format=json', '--out=tmp/rubocop-output']) do
          Pathname.new('tmp/rubocop-output').write(rubocop_json)
        end
      end

      context 'pack has no current rubocop todo' do
        before { write_file('packs/my_pack/.rubocop.yml') }

        it 'creates the TODO' do
          expect(rubocop_todo_yml).to_not exist
          RuboCop::Packs.regenerate_todo(files: ['packs/my_pack/path/to/file.rb', 'packs/my_pack/path/to/other_file.rb'])
          expect(rubocop_todo_yml).to exist
          expect(YAML.load_file(rubocop_todo_yml)).to eq(
            {
              'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/file.rb'] },
              'Packs/ClassMethodsAsPublicApis' => { 'Exclude' => ['path/to/file.rb'] }
            }
          )
        end
      end

      context 'pack does not use pack-based rubocop' do
        it 'does not create the TODO' do
          expect(rubocop_todo_yml).to_not exist
          RuboCop::Packs.regenerate_todo(files: ['packs/my_pack/path/to/file.rb'])
          expect(rubocop_todo_yml).to_not exist
        end
      end

      context 'pack has an existing rubocop todo' do
        before do
          rubocop_todo_yml.write(
            YAML.dump(
              {
                'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/existing_file.rb'] },
                'Packs/TypedPublicApis' => { 'Exclude' => ['path/to/file.rb'] }
              }
            )
          )
          write_file('packs/my_pack/.rubocop.yml')
        end

        it 'adds to the TODO with the new files' do
          expect(rubocop_todo_yml).to exist
          RuboCop::Packs.regenerate_todo(files: ['packs/my_pack/path/to/file.rb'])
          expect(rubocop_todo_yml).to exist
          expect(YAML.load_file(rubocop_todo_yml)).to eq(
            {
              'Packs/RootNamespaceIsPackName' => { 'Exclude' => ['path/to/existing_file.rb', 'path/to/file.rb'] },
              'Packs/TypedPublicApis' => { 'Exclude' => ['path/to/file.rb'] },
              'Packs/ClassMethodsAsPublicApis' => { 'Exclude' => ['path/to/file.rb'] }
            }
          )
        end
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
          write_pack('packs/some_pack')

          write_file('packs/some_pack/app/services/bad_namespace.rb', '')

          write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
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
          write_pack('packs/some_pack')

          write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
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
          write_pack('packs/some_pack')
          write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
            SomeOtherCop:
              Exclude:
                - 'packs/some_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/.rubocop_todo.yml contains invalid configuration for SomeOtherCop.
            Please only configure the following cops on a per-pack basis: ["Packs/RootNamespaceIsPackName", "Packs/TypedPublicApis", "Packs/ClassMethodsAsPublicApis"]"
            For ignoring other cops, please instead modify the top-level .rubocop_todo.yml file.
          ERROR
          expect(errors).to eq([error])
        end
      end

      context 'one pack with disallowed configuration key' do
        before do
          write_pack('packs/some_pack')
          write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              SomethingElse:
                - 'packs/some_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/.rubocop_todo.yml contains invalid configuration for Packs/RootNamespaceIsPackName.
            Please ensure the only configuration for Packs/RootNamespaceIsPackName is `Exclude`
          ERROR
          expect(errors).to eq([error])
        end
      end

      context 'one pack with filepath from the wrong pack' do
        before do
          write_pack('packs/some_pack')

          write_pack('packs/some_other_pack')

          write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              Exclude:
                - 'packs/some_other_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/.rubocop_todo.yml contains invalid configuration for Packs/RootNamespaceIsPackName.
            packs/some_other_pack/app/services/bad_namespace.rb does not belong to packs/some_pack. Please ensure you only add exclusions
            for files within this pack.
          ERROR

          expect(errors).to eq([error])
        end
      end

      context 'one pack with inherit_from set' do
        before do
          write_pack('packs/some_pack')

          write_file('packs/some_pack/.rubocop.yml', <<~YML)
            inherit_from: "something_else.yml"
          YML
        end

        it 'returns an empty list' do
          expect(errors).to be_empty
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
          write_pack('packs/some_pack')
          write_file('packs/some_pack/.rubocop.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              Enabled: true
          YML
        end

        it 'returns an empty list' do
          expect(errors).to be_empty
        end
      end

      context 'one pack with valid .rubocop.yml with FailureMode specified' do
        before do
          write_pack('packs/some_pack')
          write_file('packs/some_pack/.rubocop.yml', <<~YML)
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
          write_pack('packs/some_pack')
          write_file('packs/some_pack/.rubocop.yml', <<~YML)
            SomeOtherCop:
              Enabled: true
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/.rubocop.yml contains invalid configuration for SomeOtherCop.
            Please only configure the following cops on a per-pack basis: ["Packs/RootNamespaceIsPackName", "Packs/TypedPublicApis", "Packs/ClassMethodsAsPublicApis"]"
            For ignoring other cops, please instead modify the top-level .rubocop.yml file.
          ERROR
          expect(errors).to eq([error])
        end
      end

      context 'one pack with disallowed configuration key' do
        before do
          write_pack('packs/some_pack')
          write_file('packs/some_pack/.rubocop.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              Exclude:
                - 'packs/some_pack/app/services/bad_namespace.rb'
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/.rubocop.yml contains invalid configuration for Packs/RootNamespaceIsPackName.
            Please ensure the only configuration for Packs/RootNamespaceIsPackName is `Enabled` and `FailureMode`
          ERROR
          expect(errors).to eq([error])
        end
      end

      context 'one pack with unspecified cops' do
        before do
          RuboCop::Packs.configure do |config|
            config.required_pack_level_cops = ['Packs/RootNamespaceIsPackName', 'Packs/TypedPublicApis']
          end
        end

        before do
          write_pack('packs/some_pack')
          write_file('packs/some_pack/.rubocop.yml', <<~YML)
            Packs/RootNamespaceIsPackName:
              Enabled: true
          YML
        end

        it 'returns an error' do
          error = <<~ERROR
            packs/some_pack/.rubocop.yml is missing configuration for Packs/TypedPublicApis.
          ERROR
          expect(errors).to eq([error])
        end
      end

      # For now, this is allowed. We might add this restriction back once we've completed the migration off of `package_protections`
      context 'one pack without a .rubocop.yml' do
        before do
          write_pack('packs/some_pack')
        end

        it 'returns no errors' do
          expect(errors).to eq([])
        end
      end
    end

    describe 'FailureMode: strict' do
      context 'package has specified FailureMode: strict for a cop' do
        context 'package has pack-based .rubocop_todo.yml entries for that cop' do
          before do
            write_pack('packs/some_pack')

            write_file('packs/some_pack/app/services/some_file.rb', '')

            write_file('packs/some_pack/.rubocop.yml', <<~YML)
              Packs/RootNamespaceIsPackName:
                Enabled: true
                FailureMode: strict
            YML

            write_file('packs/some_pack/.rubocop_todo.yml', <<~YML)
              Packs/RootNamespaceIsPackName:
                Exclude:
                  - 'packs/some_pack/app/services/some_file.rb'
            YML
          end

          it 'returns an empty list' do
            expect(errors).to eq([
                                   'packs/some_pack has set `Packs/RootNamespaceIsPackName` to `FailureMode: strict` in `packs/some_pack/.rubocop.yml`, forbidding new exceptions. Please either remove `packs/some_pack/app/services/some_file.rb` from the top-level and pack-specific `.rubocop_todo.yml` files or remove `FailureMode: strict`.'
                                 ])
          end
        end

        context 'package has top-level .rubocop_todo.yml entries for that cop' do
          before do
            write_pack('packs/some_pack')

            write_file('packs/some_pack/app/services/some_file.rb', '')

            write_file('packs/some_pack/.rubocop.yml', <<~YML)
              Packs/RootNamespaceIsPackName:
                Enabled: true
                FailureMode: strict
            YML

            write_file('.rubocop_todo.yml', <<~YML)
              Packs/RootNamespaceIsPackName:
                Exclude:
                  - 'packs/some_pack/app/services/some_file.rb'
            YML
          end

          it 'returns an empty list' do
            expect(errors).to eq([
                                   'packs/some_pack has set `Packs/RootNamespaceIsPackName` to `FailureMode: strict` in `packs/some_pack/.rubocop.yml`, forbidding new exceptions. Please either remove `packs/some_pack/app/services/some_file.rb` from the top-level and pack-specific `.rubocop_todo.yml` files or remove `FailureMode: strict`.'
                                 ])
          end
        end
      end
    end
  end
end
