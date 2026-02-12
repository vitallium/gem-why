# frozen_string_literal: true

require "test_helper"
require "json"
require "gem_why/dependent"
require "gem_why/json_outputter"
require "gem_why/tree_builder"

class TestJSONOutputter < Minitest::Test
  def setup
    @messages = []
    messages = @messages
    @command = Object.new
    @command.define_singleton_method(:say) { |msg| messages << msg }
    @tree_builder = GemWhy::TreeBuilder.new
    @outputter = GemWhy::JSONOutputter.new(@command, @tree_builder)
  end

  def test_output_direct_serializes_dependents
    dependents = [GemWhy::Dependent.new(name: "alpha", version: "1.0.0", requirement: ">= 13.0")]

    @outputter.output_direct("rake", dependents)
    assert_equal expected_direct_json, parsed_output
  end

  def test_output_deep_serializes_trimmed_chains
    @outputter.output_deep("rake", deep_chains)
    output = parsed_output

    assert_equal "deep", output["mode"]
    assert_equal 2, output["root_gems"]
    assert_equal 2, output["total_chains"]
    assert_equal expected_deep_chains, output["chains"]
  end

  def test_output_tree_serializes_roots
    stub_gem_versions("alpha" => "1.0.0", "beta" => "2.0.0")
    @outputter.output_tree("rake", deep_chains)

    output = parsed_output
    assert_equal "tree", output["mode"]
    assert_equal 2, output["total_roots"]
    assert_equal expected_roots, output["roots"]
  end

  private

  def parsed_output
    JSON.parse(@messages.last)
  end

  def expected_direct_json
    {
      "target" => "rake",
      "mode" => "direct",
      "dependents" => [{ "name" => "alpha", "version" => "1.0.0", "requirement" => ">= 13.0" }],
      "total" => 1
    }
  end

  def deep_chains
    [
      [{ name: "alpha", version: "1.0", dependency: "rake", requirement: ">= 13", extra: "ignored" }],
      [{ name: "beta", version: "2.0", dependency: "rake", requirement: "~> 13", extra: "ignored" }]
    ]
  end

  def expected_deep_chains
    [
      [{ "name" => "alpha", "version" => "1.0", "dependency" => "rake", "requirement" => ">= 13" }],
      [{ "name" => "beta", "version" => "2.0", "dependency" => "rake", "requirement" => "~> 13" }]
    ]
  end

  def expected_roots
    [expected_root("alpha", "1.0.0", "1.0", ">= 13"), expected_root("beta", "2.0.0", "2.0", "~> 13")]
  end

  def expected_root(name, version, chain_version, requirement)
    {
      "name" => name,
      "version" => version,
      "tree" => { "#{name} (#{chain_version})" => tree_node("rake", requirement) }
    }
  end

  def tree_node(dependency, requirement)
    { "dependency" => dependency, "requirement" => requirement, "children" => {} }
  end

  def stub_gem_versions(versions)
    versions.each do |name, version|
      spec = mock("gem_spec")
      spec.stubs(:version).returns(Gem::Version.new(version))
      Gem::Specification.expects(:find_by_name).with(name).returns(spec)
    end
  end
end
