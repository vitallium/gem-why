# frozen_string_literal: true

require_relative "base_formatter"

module GemWhy
  module Formatters
    # Formats deep dependency chains output
    class DeepFormatter < BaseFormatter
      # Formats and displays deep dependency chains
      # @param gem_name [String] the target gem name
      # @param chains [Array<Array<Hash>>] the dependency chains
      # @return [void]
      def format(gem_name, chains)
        return say "No gems depend on #{colorize(gem_name, :yellow)}" if chains.empty?

        say "Dependency chains leading to #{colorize(gem_name, :cyan)}:\n\n"
        print_dependency_chains(chains, gem_name)
        print_deep_summary(chains, gem_name)
      end

      private

      def print_dependency_chains(chains, gem_name)
        chains_by_root = chains.group_by { |chain| chain.first[:name] }

        chains_by_root.each_value do |root_chains|
          root_chains.each do |chain|
            display_chain(chain, gem_name)
            say ""
          end
        end
      end

      def print_deep_summary(chains, gem_name)
        chains_by_root = chains.group_by { |chain| chain.first[:name] }
        root_gems = chains_by_root.keys

        say "#{colorize("Total:", :green)} #{root_gems.size} root gem(s) depend on #{gem_name}"
        say "Found #{chains.size} dependency chain(s)"
        say "\n#{colorize("Tip:", :yellow)} Use --direct for direct dependencies only or --tree for a visual tree"
      end

      def display_chain(chain, gem_name)
        path_str = chain.map { |node| colorize(node[:name], :blue) }.join(" #{colorize("=>", :white)} ")
        path_str += " #{colorize("=>", :white)} #{colorize(gem_name, :cyan)}"
        say "  #{path_str}"

        chain.each_with_index do |node, idx|
          display_chain_node(node, idx)
        end
      end

      def display_chain_node(node, idx)
        indent = "    " * (idx + 1)
        requirement = "#{node[:dependency]} #{node[:requirement]}"
        say "#{indent}└─ #{node[:name]} (#{node[:version]}) requires #{requirement}"
      end
    end
  end
end
