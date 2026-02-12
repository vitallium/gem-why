# frozen_string_literal: true

require "test_helper"
require "gem_why/dependent"

class TestDependent < Minitest::Test
  def test_to_h_returns_all_attributes
    dependent = GemWhy::Dependent.new(name: "alpha", version: "1.2.3", requirement: ">= 1.0")

    assert_equal({ name: "alpha", version: "1.2.3", requirement: ">= 1.0" }, dependent.to_h)
  end
end
