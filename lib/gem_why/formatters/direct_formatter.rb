# frozen_string_literal: true

require_relative "base_formatter"

module GemWhy
  module Formatters
    # Formats direct dependencies output
    class DirectFormatter < BaseFormatter
      # Formats and displays direct dependencies
      # @param gem_name [String] the target gem name
      # @param dependents [Array<Dependent>] the dependent gems
      # @return [void]
      def format(gem_name, dependents)
        return say "No gems depend on #{colorize(gem_name, :yellow)}" if dependents.empty?

        say "Gems that depend on #{colorize(gem_name, :cyan)}:\n\n"
        print_direct_dependents(dependents, gem_name)
        say "\n#{colorize("Total:", :green)} #{dependents.size} gem(s)"
      end

      private

      def print_direct_dependents(dependents, gem_name)
        dependents.each do |dependent|
          say "  #{colorize(dependent.name,
                            :blue)} (#{dependent.version}) requires #{gem_name} #{dependent.requirement}"
        end
      end
    end
  end
end
