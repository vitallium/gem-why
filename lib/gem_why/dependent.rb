# frozen_string_literal: true

module GemWhy
  # Represents a gem that depends on a target gem
  Dependent = Data.define(:name, :version, :requirement) do
    # Returns the dependent as a hash
    # @return [Hash] hash representation
    def to_h
      { name:, version:, requirement: }
    end
  end
end
