# frozen_string_literal: true

module  Chamber
module  Keys
class   Base
  def self.resolve(*args)
    new(*args).resolve
  end

  attr_accessor :rootpath
  attr_reader   :filenames,
                :namespaces

  def initialize(options = {})
    self.rootpath   = Pathname.new(options.fetch(:rootpath))
    self.namespaces = options.fetch(:namespaces)
    self.filenames  = options[:filenames]
  end

  def resolve
    key_paths.each_with_object({}) do |path, memo|
      namespace = namespace_from_path(path) || '__default'
      value     = path.readable? ? path.read : ENV[environment_variable_from_path(path)]

      memo[namespace.downcase.to_sym] = value if value
    end
  end

  private

  def key_paths
    @key_paths = (filenames.any? ? filenames : [default_key_file_path]) +
                 namespaces.map { |n| namespace_to_key_path(n) }
  end

  # rubocop:disable Performance/ChainArrayAllocation
  def filenames=(other)
    @filenames = Array(other).
                   map { |o| Pathname.new(o) }.
                   compact
  end
  # rubocop:enable Performance/ChainArrayAllocation

  def namespaces=(other)
    @namespaces = other + %w{signature}
  end

  def namespace_from_path(path)
    path.
      basename.
      to_s.
      match(self.class::NAMESPACE_PATTERN) { |m| m[1].upcase }
  end

  def namespace_to_key_path(namespace)
    rootpath + ".chamber.#{namespace.to_s.tr('.-', '')}#{key_filename_extension}"
  end

  def default_key_file_path
    Pathname.new(rootpath + ".chamber#{key_filename_extension}")
  end
end
end
end
