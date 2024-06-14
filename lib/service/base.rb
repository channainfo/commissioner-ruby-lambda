require 'interactor'
require 'active_support'
require 'active_support/core_ext/module/delegation'

module Service
  class Base
    include Interactor
  end
end