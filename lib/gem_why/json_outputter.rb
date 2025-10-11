# frozen_string_literal: true

require "json"

module GemWhy
  # Handles JSON output for all display modes
  class JSONOutputter
    attr_reader :command, :tree_builder

    def initialize(command, tree_builder)
      @command = command
      @tree_builder = tree_builder
    end

    # Outputs direct dependencies as JSON
    # @param gem_name [String] the target gem name
    # @param dependents [Array<Array(String, String, String)>] the dependent gems
    # @return [void]
    def output_direct(gem_name, dependents)
      target = gem_name
      mode = "direct"
      total = dependents.size
      dependents_data = dependents.map do |name, version, requirement|
        { name:, version:, requirement: }
      end
      output = { target:, mode:, dependents: dependents_data, total: }
      say JSON.pretty_generate(output)
    end

    # Outputs deep dependency chains as JSON
    # @param gem_name [String] the target gem name
    # @param chains [Array<Array<Hash>>] the dependency chains
    # @return [void]
    def output_deep(gem_name, chains)
      chains_by_root = chains.group_by { |chain| chain.first[:name] }
      target = gem_name
      mode = "deep"
      chains_data = chains.map { |chain| chain.map { |node| node.slice(:name, :version, :dependency, :requirement) } }
      root_gems = chains_by_root.keys.size
      total_chains = chains.size
      output = { target:, mode:, chains: chains_data, root_gems:, total_chains: }
      say JSON.pretty_generate(output)
    end

    # Outputs dependency tree as JSON
    # @param gem_name [String] the target gem name
    # @param chains [Array<Array<Hash>>] the dependency chains
    # @return [void]
    def output_tree(gem_name, chains)
      chains_by_root = chains.group_by { |chain| chain.first[:name] }
      target = gem_name
      mode = "tree"
      roots = build_json_roots(chains_by_root)
      total_roots = chains_by_root.keys.size
      output = { target:, mode:, roots:, total_roots: }
      say JSON.pretty_generate(output)
    end

    private

    def build_json_roots(chains_by_root)
      chains_by_root.map do |root_name, root_chains|
        root_spec = Gem::Specification.find_by_name(root_name)
        name = root_name
        version = root_spec.version.to_s
        tree = tree_builder.build_tree_structure(root_chains)
        { name:, version:, tree: }
      end
    end

    def say(message)
      command.say(message)
    end
  end
end
