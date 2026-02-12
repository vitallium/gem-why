# frozen_string_literal: true

require "test_helper"
require "gem_why/analyzer"

class TestAnalyzer < Minitest::Test
  def setup
    @analyzer = GemWhy::Analyzer.new
  end

  def test_find_direct_dependents_uses_runtime_dependencies_and_sorts
    specs = direct_dependent_specs

    with_specification_stubs(each_specs: specs, lookup_specs: specs_by_name(specs)) do
      assert_expected_direct_dependents(@analyzer.find_direct_dependents("target"))
    end
  end

  def test_find_dependency_chains_returns_unique_sorted_chains
    each_specs, lookup_specs = chain_specs

    with_specification_stubs(each_specs:, lookup_specs:) do
      assert_expected_dependency_chains(@analyzer.find_dependency_chains("TARGET"))
    end
  end

  def test_find_dependency_chains_handles_cycles_and_missing_specs
    each_specs, lookup_specs = cyclic_and_missing_specs

    with_specification_stubs(each_specs:, lookup_specs:) do
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

  def specs_by_name(specs)
    specs.to_h { |single_spec| [single_spec.name, single_spec] }
  end

  def spec(name, version, runtime:, deps:)
    Struct.new(:name, :version, :runtime_dependencies, :dependencies, keyword_init: true)
          .new(name:, version: Gem::Version.new(version), runtime_dependencies: runtime, dependencies: deps)
  end

  def dep(name, requirement)
    Gem::Dependency.new(name, requirement)
  end

  def with_specification_stubs(each_specs:, lookup_specs:)
    spec_singleton = Gem::Specification.singleton_class
    originals = specification_originals(spec_singleton)
    apply_specification_stubs(spec_singleton, each_specs, lookup_specs)
    yield
  ensure
    restore_specification_methods(spec_singleton, originals)
  end

  def specification_originals(spec_singleton)
    {
      flat_map: spec_singleton.instance_method(:flat_map),
      each: spec_singleton.instance_method(:each),
      find_by_name: spec_singleton.instance_method(:find_by_name)
    }
  end

  def apply_specification_stubs(spec_singleton, each_specs, lookup_specs)
    spec_singleton.send(:define_method, :flat_map) { |&block| each_specs.flat_map(&block) }
    spec_singleton.send(:define_method, :each) { |&block| each_specs.each(&block) }
    spec_singleton.send(:define_method, :find_by_name) do |name|
      lookup_specs.fetch(name) { raise Gem::MissingSpecError.new(name, nil) }
    end
  end

  def restore_specification_methods(spec_singleton, originals)
    originals.each do |method_name, original_method|
      spec_singleton.send(:define_method, method_name, original_method)
    end
  end
end
