# typed: strict

module Kuby
  module Docker
    module Packages
      autoload :ManagedPackage,       'kuby/docker/packages/managed_package'
      autoload :Package,              'kuby/docker/packages/package'
      autoload :SimpleManagedPackage, 'kuby/docker/packages/simple_managed_package'
    end
  end
end
