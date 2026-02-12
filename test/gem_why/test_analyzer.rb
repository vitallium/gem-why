# frozen_string_literal: true

require "test_helper"
require "gem_why/analyzer"

class TestAnalyzer < Minitest::Test
  def setup
    @analyzer = GemWhy::Analyzer.new
  end

  def test_find_direct_dependents_uses_runtime_dependencies_and_sorts
    specs = direct_dependent_specs

    Gem::Specification.expects(:flat_map).returns(specs.flat_map(&method(:direct_dependents_from_spec)))

    assert_expected_direct_dependents(@analyzer.find_direct_dependents("target"))
  end

  def test_find_dependency_chains_returns_unique_sorted_chains
    each_specs, lookup_specs = chain_specs

    stub_gem_specification_methods(each_specs: each_specs, lookup_specs: lookup_specs) do
      assert_expected_dependency_chains(@analyzer.find_dependency_chains("TARGET"))
    end
  end

  def test_find_dependency_chains_handles_cycles_and_missing_specs
    each_specs, lookup_specs = cyclic_and_missing_specs

    stub_gem_specification_methods(each_specs: each_specs, lookup_specs: lookup_specs) do
      assert_empty @analyzer.find_dependency_chains("target")
    end
  end

  private

  def assert_expected_direct_dependents(dependents)
    assert_equal %w[alpha zeta], dependents.map(&:name)
    assert_equal %w[2.0 1.0], dependents.map(&:version)
    assert_equal ["~> 3.0", ">= 1.0"], dependents.map(&:requirement)
  end

  def assert_expected_dependency_chains(chains)
    assert_equal(%w[alpha beta mid], chains.map { |chain| chain.first[:name] })
    assert_equal 3, chains.size
    assert_includes chains, [
      { name: "mid", version: "2.0", dependency: "target", requirement: "~> 3.0" }
    ]
  end

  def direct_dependent_specs
    [
      spec("zeta", "1.0", runtime: [dep("target", ">= 1.0")], deps: [dep("target", "= 9.9")]),
      spec("alpha", "2.0", runtime: [dep("TARGET", "~> 3.0")], deps: []),
      spec("ignored", "3.0", runtime: [], deps: [dep("target", "= 1.0")])
    ]
  end

  def chain_specs
    target = spec("target", "3.0", runtime: [], deps: [])
    mid = spec("mid", "2.0", runtime: [], deps: [dep("target", "~> 3.0")])
    alpha = spec("alpha", "1.0", runtime: [], deps: [dep("mid", ">= 2.0")])
    beta = spec("beta", "1.1", runtime: [], deps: [dep("mid", ">= 2.0")])
    each_specs = [alpha, beta, mid, alpha]
    lookup_specs = { "target" => target, "mid" => mid, "alpha" => alpha, "beta" => beta }
    [each_specs, lookup_specs]
  end

  def cyclic_and_missing_specs
    loop_a = spec("loop_a", "1.0", runtime: [], deps: [dep("loop_b", ">= 1.0")])
    loop_b = spec("loop_b", "1.0", runtime: [], deps: [dep("loop_a", ">= 1.0")])
    missing_root = spec("missing_root", "1.0", runtime: [], deps: [dep("ghost", ">= 1.0")])

    each_specs = [loop_a, missing_root]
    lookup_specs = { "loop_a" => loop_a, "loop_b" => loop_b, "missing_root" => missing_root }
    [each_specs, lookup_specs]
  end

  def spec(name, version, runtime:, deps:)
    spec = mock("gem_spec_#{name}")
    spec.stubs(:name).returns(name)
    spec.stubs(:version).returns(Gem::Version.new(version))
    spec.stubs(:runtime_dependencies).returns(runtime)
    spec.stubs(:dependencies).returns(deps)
    spec
  end

  def dep(name, requirement)
    Gem::Dependency.new(name, requirement)
  end

  def direct_dependents_from_spec(spec)
    spec.runtime_dependencies
        .filter { |dep| dep.name.downcase == "target" }
        .map { |dep| GemWhy::Dependent.new(name: spec.name, version: spec.version.to_s, requirement: dep.requirement.to_s) }
  end

  def stub_gem_specification_methods(each_specs:, lookup_specs:)
    Gem::Specification.expects(:each).multiple_yields(*each_specs)

    # Target gem is never loaded since matching stops at the dependency
    lookup_specs.each do |name, spec|
      next if name == "target"

      Gem::Specification.expects(:find_by_name).with(name).returns(spec).at_least_once
    end

    stub_missing_spec if lookup_specs.key?("missing_root")
    yield
  end

  def stub_missing_spec
    Gem::Specification.expects(:find_by_name).with("ghost").raises(
      Gem::MissingSpecError.new("ghost", nil)
    ).at_most_once
  end
end
