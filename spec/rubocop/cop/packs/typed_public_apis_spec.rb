# typed: false

RSpec.describe RuboCop::Cop::Packs::TypedPublicApis, :config do
  let(:config) do
    RuboCop::Config.new
  end

  context 'a private class is typed false' do
    let(:source) do
      <<~RUBY
        # typed: false
        class Foo
        end
      RUBY
    end

    it { expect_no_offenses source, 'packs/foo/app/services/foo.rb' }
  end

  context 'a public class is typed false' do
    let(:source) do
      <<~RUBY
        # typed: false
        ^^^^^^^^^^^^^^ Sorbet sigil should be at least `strict` got `false`.
        class Foo
        end
      RUBY
    end

    it { expect_offense source, 'packs/foo/app/public/foo.rb' }
  end
end
