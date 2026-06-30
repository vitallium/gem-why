# frozen_string_literal: true

require "test_helper"
require "rubygems/commands/why_command"
require "stringio"
require "json"

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

  def test_version_flag_shows_version
    setup_ui
    @command.handle_options ["--version"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    assert_includes @output.string, GemWhy::VERSION
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

  # ============================================================
  # Integration tests - test actual behavior through public API
  # ============================================================

  def test_deep_mode_shows_dependency_chains
    setup_ui
    @command.handle_options ["rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    assert_includes @output.string, "Dependency chains leading to"
    assert_includes @output.string, "rainbow"
    assert_includes @output.string, "Total:"
    assert_includes @output.string, "dependency chain"
  end

  def test_deep_mode_shows_multiple_root_gems
    setup_ui
    @command.handle_options ["prism"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    assert_includes @output.string, "root gem(s) depend on prism"
  end

  def test_direct_mode_shows_only_immediate_dependents
    setup_ui
    @command.handle_options ["--direct", "rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    assert_includes @output.string, "Gems that depend on"
    assert_includes @output.string, "rainbow"
    assert_includes @output.string, "Total:"
    refute_includes @output.string, "dependency chain"
  end

  def test_direct_mode_output_format
    setup_ui
    @command.handle_options ["--direct", "rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    assert_match(/requires rainbow/, @output.string)
  end

  def test_tree_mode_shows_hierarchical_structure
    setup_ui
    @command.handle_options ["--tree", "rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    assert_includes @output.string, "Dependency tree for"
    assert_includes @output.string, "rainbow"
    assert_includes @output.string, "Total:"
  end

  def test_tree_mode_includes_visual_indicators
    setup_ui
    @command.handle_options ["--tree", "rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    assert_match(/[├└│]/, @output.string) || assert_match(/[+`-]/, @output.string)
  end

  def test_json_deep_mode_returns_valid_json
    setup_ui
    @command.handle_options ["--json", "rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    data = JSON.parse(@output.string)
    assert_equal "deep", data["mode"]
    assert data.key?("chains")
    assert data.key?("root_gems")
    assert data.key?("total_chains")
  end

  def test_json_deep_mode_chain_structure
    setup_ui
    @command.handle_options ["--json", "rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    data = JSON.parse(@output.string)
    assert_kind_of Array, data["chains"]
    
    data["chains"].each do |chain|
      assert_kind_of Array, chain
      chain.each do |node|
        assert node.key?("name")
        assert node.key?("version")
        assert node.key?("dependency")
        assert node.key?("requirement")
      end
    end
  end

  def test_json_direct_mode_returns_valid_json
    setup_ui
    @command.handle_options ["--json", "--direct", "rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    data = JSON.parse(@output.string)
    assert_equal "direct", data["mode"]
    assert data.key?("dependents")
    assert data.key?("total")
    
    data["dependents"].each do |dep|
      assert dep.key?("name")
      assert dep.key?("version")
      assert dep.key?("requirement")
    end
  end

  def test_json_tree_mode_returns_valid_json
    setup_ui
    @command.handle_options ["--json", "--tree", "rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    data = JSON.parse(@output.string)
    assert_equal "tree", data["mode"]
    assert data.key?("roots")
    assert data.key?("total_roots")
    
    data["roots"].each do |root|
      assert root.key?("name")
      assert root.key?("version")
      assert root.key?("tree")
    end
  end

  def test_search_for_prism_finds_dependents
    setup_ui
    @command.handle_options ["prism"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    assert_includes @output.string, "root gem(s) depend on prism"
  end

  def test_search_for_pp_finds_dependents
    setup_ui
    @command.handle_options ["pp"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    assert_includes @output.string, "Dependency chains leading to pp"
  end

  def test_deep_and_direct_modes_both_find_dependencies
    setup_ui
    @command.handle_options ["rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end
    deep_result = @output.string

    @command = Gem::Commands::WhyCommand.new
    setup_ui
    @command.handle_options ["--direct", "rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end
    direct_result = @output.string

    assert_includes deep_result, "rainbow"
    assert_includes direct_result, "rainbow"
  end

  def test_tree_mode_includes_all_information_from_deep_mode
    setup_ui
    @command.handle_options ["--tree", "rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    assert_includes @output.string, "rainbow"
  end

  def test_no_color_option_disables_colors
    setup_ui
    @command.handle_options ["--no-color", "rainbow"]

    Gem::DefaultUserInteraction.use_ui(@ui) do
      @command.execute
    end

    assert_includes @output.string, "rainbow"
  end

  private

  def setup_ui
    @output = StringIO.new
    @ui = Gem::StreamUI.new(StringIO.new, @output, @output)
  end
end
