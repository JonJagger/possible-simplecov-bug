# frozen_string_literal: true
require_relative 'http_json'
require 'json'

class RackDispatcher

  def initialize(creator, request_class)
    @creator = creator
    @request_class = request_class
  end

  def call(env)
    request = @request_class.new(env)
    path = request.path_info
    name,args = HttpJson.new.get(path)
    result = @creator.public_send(name, *args)
    json_response(200, { name => result })
  rescue Exception => error
    json_response(500, diagnostic(path, body, error))
  end

  private

  def json_response(status, json)
    if status === 200
      body = JSON.fast_generate(json)
    else
      body = JSON.pretty_generate(json)
      $stderr.puts(body)
    end
    [ status,
      { 'Content-Type' => 'application/json' },
      [ body ]
    ]
  end

  # - - - - - - - - - - - - - - - -

  def diagnostic(path, body, error)
    { 'exception' => {
        'path' => path,
        'body' => body,
        'class' => 'Creator',
        'message' => error.message,
        'backtrace' => error.backtrace
      }
    }
  end

end
