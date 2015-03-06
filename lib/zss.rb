
require 'active_support/string_inquirer'
require 'active_support/core_ext/object'
require 'active_support/core_ext/hash/indifferent_access'

require 'logger_facade'

require_relative 'zss/require'
require_relative 'zss/validate'
require_relative 'zss/version'
require_relative 'zss/environment'
require_relative 'zss/configuration'
require_relative 'zss/message'
require_relative 'zss/error'


module ZSS
  extend self

end
