# typed: strict
# frozen_string_literal: true

require 'fileutils'

module ApplicationFixtureHelper
  extend T::Sig

  sig { params(path: String, content: String).returns(String) }
  def write_file(path, content = '')
    pathname = Pathname.new(path)
    FileUtils.mkdir_p(pathname.dirname)
    pathname.write(content)
    path
  end

  sig do
    params(
      pack_name: String,
      config: T::Hash[T.untyped, T.untyped]
    ).void
  end
  def write_package_yml(
    pack_name,
    config = {}
  )
    path = Pathname.pwd.join(pack_name).join('package.yml')
    write_file(path.to_s, YAML.dump(config))
  end

  sig { params(path: String).void }
  def delete_app_file(path)
    File.delete(path)
  end
end
