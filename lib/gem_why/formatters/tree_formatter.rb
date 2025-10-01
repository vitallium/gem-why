# frozen_string_literal: true

require_relative "base_formatter"

module GemWhy
  module Formatters
    # Formats tree visualization output
    class TreeFormatter < BaseFormatter
      attr_reader :tree_builder

      def initialize(command, tree_builder)
        super(command)
        @tree_builder = tree_builder
      end

      # Formats and displays dependency tree
      # @param gem_name [String] the target gem name
      # @param chains [Array<Array<Hash>>] the dependency chains
      # @return [void]
      def format(gem_name, chains)
        return say "No gems depend on #{colorize(gem_name, :yellow)}" if chains.empty?

        say "Dependency tree for #{colorize(gem_name, :cyan)}:\n\n"
        print_dependency_tree(chains, gem_name)
        print_tree_summary(chains, gem_name)
      end

      private

      def print_dependency_tree(chains, gem_name)
        chains_by_root = chains.group_by { |chain| chain.first[:name] }

        chains_by_root.each do |root_name, root_chains|
          print_root_tree(root_name, root_chains, gem_name)
        end
      end

      def print_root_tree(root_name, root_chains, gem_name)
        root_spec = Gem::Specification.find_by_name(root_name)
        say "#{colorize(root_name, :blue)} (#{root_spec.version})"

        tree = tree_builder.build_tree_structure(root_chains)
        display_tree_node(tree, "", gem_name)

        say ""
      end

      def print_tree_summary(chains, gem_name)
        chains_by_root = chains.group_by { |chain| chain.first[:name] }
        root_gems = chains_by_root.keys
        say "#{colorize("Total:", :green)} #{root_gems.size} root gem(s) depend on #{gem_name}"
      end

      def display_tree_node(tree, prefix, target_gem, depth = 0)
        return if tree.empty?

        tree.each_with_index do |(key, value), index|
          is_last = index == tree.size - 1
          display_node_line(key, value, prefix, is_last, depth)
          display_children_or_target(value, prefix, is_last, target_gem, depth)
        end
      end

      def display_node_line(key, value, prefix, is_last, depth)
        connector = is_last ? "└──" : "├──"
        line = build_node_line(key, value, depth)
        say "#{prefix}#{connector} #{line}"
      end

      def build_node_line(key, value, depth)
        if depth.zero?
          "#{value[:dependency]} #{value[:requirement]}"
        else
          "#{key} requires #{value[:dependency]} #{value[:requirement]}"
        end
      end

      def display_children_or_target(value, prefix, is_last, target_gem, depth)
        new_prefix = prefix + (is_last ? "    " : "│   ")

        if value[:children].empty?
          say "#{new_prefix}└── #{colorize(target_gem, :cyan)} #{colorize("✓", :green)}"
        else
          display_tree_node(value[:children], new_prefix, target_gem, depth + 1)
        end
      end
    end
  end
end
