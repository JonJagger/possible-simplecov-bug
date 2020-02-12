# frozen_string_literal: true

class HttpJson

  class Error < RuntimeError
    def initialize(message)
      super
    end
  end

  def get(path)
    case path
    when '/ready' then ['ready?',[]]
    else
      raise Error.new('unknown path')
    end
  end

end
