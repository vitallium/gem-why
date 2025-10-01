# frozen_string_literal: true

require_relative "base_formatter"

module GemWhy
  module Formatters
    # Formats direct dependencies output
    class DirectFormatter < BaseFormatter
      # Formats and displays direct dependencies
      # @param gem_name [String] the target gem name
      # @param dependents [Array<Array(String, String)>] the dependent gems
      # @return [void]
      def format(gem_name, dependents)
        return say "No gems depend on #{colorize(gem_name, :yellow)}" if dependents.empty?

        say "Gems that depend on #{colorize(gem_name, :cyan)}:\n\n"
        print_direct_dependents(dependents, gem_name)
        say "\n#{colorize("Total:", :green)} #{dependents.size} gem(s)"
      end

      private

      def print_direct_dependents(dependents, gem_name)
        dependents.each do |dependent_name, requirement|
          spec = Gem::Specification.find_by_name(dependent_name)
          say "  #{colorize(dependent_name, :blue)} (#{spec.version}) requires #{gem_name} #{requirement}"
        end
      end
    end
  end
end
