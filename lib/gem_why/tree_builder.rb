# frozen_string_literal: true

module GemWhy
  # Builds tree structures from dependency chains
  class TreeBuilder
    # Builds a tree structure from dependency chains
    # @param chains [Array<Array<Hash>>] the dependency chains
    # @return [Hash] hierarchical tree structure
    def build_tree_structure(chains)
      tree = {}

      chains.each do |chain|
        add_chain_to_tree(tree, chain)
      end

      tree
    end

    private

    def add_chain_to_tree(tree, chain)
      current_level = tree

      chain.each do |node|
        key = "#{node[:name]} (#{node[:version]})"
        current_level[key] ||= create_tree_node(node)
        current_level = current_level[key][:children]
      end
    end

    def create_tree_node(node)
      dependency = node[:dependency]
      requirement = node[:requirement]
      children = {}
      { dependency:, requirement:, children: }
    end
  end
end
