# frozen_string_literal: true

require "test_helper"
require "gem_why/dependent"
require "gem_why/formatters/direct_formatter"

class TestDirectFormatter < Minitest::Test
  def setup
    @messages = []
    messages = @messages
    @command = Object.new
    @command.define_singleton_method(:options) { { no_color: true } }
    @command.define_singleton_method(:say) { |msg| messages << msg }
    @formatter = GemWhy::Formatters::DirectFormatter.new(@command)
  end

  def test_format_with_no_dependents
    @formatter.format("rake", [])

    assert_equal ["No gems depend on rake"], @messages
  end

  def test_format_with_dependents_prints_entries_and_total
    @formatter.format("rake", direct_dependents)

    assert_equal expected_messages, @messages
  end

  private

  def direct_dependents
    [
      GemWhy::Dependent.new(name: "alpha", version: "1.0.0", requirement: ">= 13.0"),
      GemWhy::Dependent.new(name: "beta", version: "2.0.0", requirement: "~> 13.0")
    ]
  end

  def expected_messages
    [
      "Gems that depend on rake:\n\n",
      "  alpha (1.0.0) requires rake >= 13.0",
      "  beta (2.0.0) requires rake ~> 13.0",
      "\nTotal: 2 gem(s)"
    ]
  end
end
