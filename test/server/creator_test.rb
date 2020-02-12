# frozen_string_literal: true
require 'minitest/autorun'

def require_src(required)
  require_relative "../../app/src/#{required}"
end

require_src 'creator'

class CreatorTest < MiniTest::Test

  def test_its_ready
    assert Creator.new.ready?
  end

end
