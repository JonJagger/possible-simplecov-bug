$stdout.sync = true
$stderr.sync = true

def require_src(name)
  require_relative "src/#{name}"
end

require_src 'creator'
require_src 'rack_dispatcher'
require 'rack'

creator = Creator.new
dispatcher = RackDispatcher.new(creator, Rack::Request)
run dispatcher
