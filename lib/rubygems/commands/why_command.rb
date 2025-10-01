# frozen_string_literal: true

require "rubygems/command"
require_relative "../../gem_why/version"
require_relative "../../gem_why/analyzer"
require_relative "../../gem_why/tree_builder"
require_relative "../../gem_why/json_outputter"
require_relative "../../gem_why/formatters/direct_formatter"
require_relative "../../gem_why/formatters/deep_formatter"
require_relative "../../gem_why/formatters/tree_formatter"

module Gem
  module Commands
    # Command to show which gems depend on a specific gem
    #
    # This command helps identify dependency relationships by showing:
    # - Direct dependencies (--direct): immediate dependents only
    # - Deep dependencies (default): full dependency chains
    # - Tree visualization (--tree): hierarchical view
    #
    # @example Show all dependency chains
    #   gem why concurrent-ruby
    #
    # @example Show only direct dependencies
    #   gem why rake --direct
    #
    # @example Show tree visualization
    #   gem why concurrent-ruby --tree
    #
    # @example Output as JSON
    #   gem why rake --json
    class WhyCommand < Gem::Command
      # Initializes the why command with options
      def initialize
        super("why", "Show which gems depend on a specific gem")
        setup_options
        initialize_dependencies
      end

      # @return [String] long description of the command
      def description
        "Show which installed gems depend on a specific gem, including dependency chains"
      end

      # @return [String] usage string for the command
      def usage
        "#{program_name} GEMNAME [options]"
      end

      # Executes the command with the provided arguments
      # @return [void]
      def execute
        gem_name = validate_gem_name
        route_to_display_mode(gem_name)
      end

      private

      attr_reader :analyzer, :tree_builder, :json_outputter, :direct_formatter, :deep_formatter, :tree_formatter

      def setup_options
        setup_tree_option
        setup_direct_option
        setup_version_option
        setup_no_color_option
        setup_json_option
      end

      def setup_tree_option
        add_option("-t", "--tree", "Display dependencies as a tree") do |value, options|
          options[:tree] = value
        end
      end

      def setup_direct_option
        add_option("-d", "--direct", "Show only direct dependencies") do |value, options|
          options[:direct] = value
        end
      end

      def setup_version_option
        add_option("-v", "--version", "Show gem-why version") do |_value, _options|
          say "gem-why version #{GemWhy::VERSION}"
          terminate_interaction
        end
      end

      def setup_no_color_option
        add_option("--no-color", "Disable colored output") do |_value, options|
          options[:no_color] = true
        end
      end

      def setup_json_option
        add_option("--json", "Output in JSON format") do |_value, options|
          options[:json] = true
        end
      end

      def initialize_dependencies
        @analyzer = GemWhy::Analyzer.new
        @tree_builder = GemWhy::TreeBuilder.new
        @json_outputter = GemWhy::JSONOutputter.new(self, tree_builder)
        @direct_formatter = GemWhy::Formatters::DirectFormatter.new(self)
        @deep_formatter = GemWhy::Formatters::DeepFormatter.new(self)
        @tree_formatter = GemWhy::Formatters::TreeFormatter.new(self, tree_builder)
      end

      # Validates and normalizes the gem name argument
      # @return [String] the normalized gem name
      # @raise [Gem::CommandLineError] if no gem name provided
      def validate_gem_name
        gem_name = get_one_optional_argument || raise(
          Gem::CommandLineError,
          "Please specify a gem name (e.g. gem why rake)"
        )
        gem_name.downcase
      end

      # Routes execution to the appropriate display mode
      # @param gem_name [String] the target gem name
      # @return [void]
      def route_to_display_mode(gem_name)
        if options[:direct]
          show_direct_dependencies(gem_name)
        elsif options[:tree]
          show_tree_visualization(gem_name)
        else
          show_deep_dependencies(gem_name)
        end
      end

      # Shows direct dependencies only
      # @param gem_name [String] the target gem name
      # @return [void]
      def show_direct_dependencies(gem_name)
        dependents = analyzer.find_direct_dependents(gem_name)

        if options[:json]
          json_outputter.output_direct(gem_name, dependents)
        else
          direct_formatter.format(gem_name, dependents)
        end
      end

      # Shows deep dependencies (full chains)
      # @param gem_name [String] the target gem name
      # @return [void]
      def show_deep_dependencies(gem_name)
        chains = analyzer.find_dependency_chains(gem_name)

        if options[:json]
          json_outputter.output_deep(gem_name, chains)
        else
          deep_formatter.format(gem_name, chains)
        end
      end

      # Shows tree visualization
      # @param gem_name [String] the target gem name
      # @return [void]
      def show_tree_visualization(gem_name)
        chains = analyzer.find_dependency_chains(gem_name)

        if options[:json]
          json_outputter.output_tree(gem_name, chains)
        else
          tree_formatter.format(gem_name, chains)
        end
      end
    end
  end
end
