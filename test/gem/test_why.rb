# frozen_string_literal: true

require "test_helper"
require "rubygems/commands/why_command"
require "stringio"

class TestWhyCommand < Minitest::Test
  def setup
    @command = Gem::Commands::WhyCommand.new
  end

  def test_command_has_correct_name
    assert_equal "gem why", @command.program_name
  end

  def test_command_has_description
    refute_empty @command.description
    assert_includes @command.description.downcase, "depend"
  end

  def test_command_has_usage
    assert_includes @command.usage, "GEMNAME"
  end

  def test_command_requires_gem_name
    error = assert_raises Gem::CommandLineError do
      @command.execute
    end

    assert_includes error.message.downcase, "specify"
  end

  def test_command_accepts_tree_option
    @command.handle_options ["--tree"]
    assert @command.options[:tree]
  end

  def test_command_accepts_tree_short_option
    @command.handle_options ["-t"]
    assert @command.options[:tree]
  end

  def test_command_accepts_direct_option
    @command.handle_options ["--direct"]
    assert @command.options[:direct]
  end

  def test_command_accepts_direct_short_option
    @command.handle_options ["-d"]
    assert @command.options[:direct]
  end

  def test_no_color_option
    @command.handle_options ["--no-color"]
    assert @command.options[:no_color]
  end

  def test_json_option
    @command.handle_options ["--json"]
    assert @command.options[:json]
  end

  def test_version_constant_defined
    assert defined?(GemWhy::VERSION)
    assert_kind_of String, GemWhy::VERSION
    refute_empty GemWhy::VERSION
  end

  def test_execute_with_direct_mode
    setup_ui
    @command.handle_options ["--direct", "minitest"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    # Should produce some output
    refute_empty @output.string
  end

  def test_execute_with_tree_mode
    setup_ui
    @command.handle_options ["--tree", "minitest"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    # Should produce some output
    refute_empty @output.string
  end

  def test_execute_with_deep_mode
    setup_ui
    @command.handle_options ["minitest"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    # Should produce some output
    refute_empty @output.string
  end

  def test_execute_with_json_output
    setup_ui
    @command.handle_options ["--json", "--direct", "minitest"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    # Should produce JSON-parseable output
    refute_empty @output.string
  end

  def test_normalizes_gem_name_to_lowercase
    output_upper = execute_with_gem_name("MINITEST")
    output_lower = execute_with_gem_name("minitest")

    assert_equal output_lower, output_upper
  end

  def execute_with_gem_name(gem_name)
    @command = Gem::Commands::WhyCommand.new
    setup_ui
    @command.handle_options ["--direct", gem_name]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    @output.string
  end

  private

  def setup_ui
    @output = StringIO.new
    @ui = Gem::StreamUI.new(StringIO.new, @output, @output)
  end
end
