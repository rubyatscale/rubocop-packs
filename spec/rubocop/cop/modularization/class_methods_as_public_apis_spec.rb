# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Modularization::ClassMethodsAsPublicApis, :config do
  let(:acceptable_parent_classes) do
    [
      'T::Struct',
      'T::Enum',
      'Objects::BaseInputObject', # GraphQL Input Object
      'Objects::BaseObject', # GraphQL Base Object
      'Mutations::BaseMutation' # GraphQL Mutation
    ]
  end
  let(:cop_config) { { 'Enabled' => true, 'AcceptableParentClasses' => acceptable_parent_classes } }
  subject(:cop) { described_class.new(config) }

  before do
    write_file('packs/tool/app/public/tool.rb')
  end

  context 'when class defines an instance method, does not inherit from anything' do
    let(:source) do
      <<~RUBY
        class Tool
          def my_instance_method
          ^^^^^^^^^^^^^^^^^^^^^^ Top-level files in the public/ folder may only define class methods.
          end
        end
      RUBY
    end

    it { expect_offense source, Pathname.pwd.join('packs/tool/app/public/tool.rb').to_s }
  end

  context 'when class defines an instance an instance method but is not in the public directory' do
    let(:source) do
      <<~RUBY
        class Tool
          def my_instance_method
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/tool/app/services/tool.rb' }
  end

  context 'when class defines an instance method with a sorbet signature' do
    let(:source) do
      <<~RUBY
        class Tool
          extend T::Sig

          sig { params(id: Integer).void }
          def my_instance_method(id)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ Top-level files in the public/ folder may only define class methods.
          end
        end
      RUBY
    end

    it { expect_offense source, Pathname.pwd.join('packs/tool/app/public/tool.rb').to_s }
  end

  context 'when class defines a singleton method' do
    let(:source) do
      <<~RUBY
        class Tool
          def self.my_singleton_method
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/tool/app/public/tool.rb' }
  end

  context 'when class defines a singleton method with a sorbet signature' do
    let(:source) do
      <<~RUBY
        class Tool
          extend T::Sig

          sig { params(id: Integer).void }
          def self.my_singleton_method(id)
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/tool/app/public/tool.rb' }
  end

  context 'when class defines a singleton method using the class << self syntax' do
    let(:source) do
      <<~RUBY
        class Tool
          class << self
            def my_singleton_method
            end
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/tool/app/public/tool.rb' }
  end

  context 'when class is within a module and it has a sorbet signature' do
    let(:source) do
      <<~RUBY
        module MyModule
          class << self
            extend T::Sig

            sig { void }
            def my_method
            end
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/tool/app/public/tool.rb' }
  end

  context 'it inherits from T::Struct and defines a helper method' do
    let(:source) do
      <<~RUBY
        class Tool < T::Struct
          def my_instance_method
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/tool/app/public/tool.rb' }
  end

  context 'it inherits from T::Struct, includes TypedStructHelper, and defines a helper method' do
    let(:source) do
      <<~RUBY
        class Tool < T::Struct
          include TypedStructHelper
          def my_instance_method
          end
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/tool/app/public/tool.rb' }
  end

  context 'it inherits from T::Enum and defines a helper method' do
    let(:source) do
      <<~RUBY
        class MyEnum < T::Enum
          extend T::Sig

          enums do
            SomeValue = new
          end

          sig { returns(String) }
          def my_allowed_method
          end
        end
      RUBY
    end

    it { expect_no_offenses source, Pathname.pwd.join(write_file('packs/tool/app/public/tool.rb')).to_s }
  end
end
