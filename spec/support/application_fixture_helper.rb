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
      dependencies: T::Array[String],
      enforce_dependencies: T::Boolean,
      enforce_privacy: T::Boolean
    ).void
  end
  def write_package_yml(
    pack_name,
    dependencies: [],
    enforce_dependencies: true,
    enforce_privacy: true
  )
    package = ParsePackwerk::Package.new(
      name: pack_name,
      dependencies: dependencies,
      enforce_dependencies: enforce_dependencies,
      enforce_privacy: enforce_privacy,
      metadata: {}
    )

    ParsePackwerk.write_package_yml!(package)
  end

  sig { params(path: String).void }
  def delete_app_file(path)
    File.delete(path)
  end
end
