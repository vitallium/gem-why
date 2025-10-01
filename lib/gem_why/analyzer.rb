# frozen_string_literal: true

module GemWhy
  # Analyzes gem dependencies to find dependents and dependency chains
  class Analyzer
    # Finds all gems that directly depend on the target gem
    # @param target_gem_name [String] the gem to find dependents for
    # @return [Array<Array(String, String)>] array of [gem_name, requirement] pairs
    def find_direct_dependents(target_gem_name)
      dependents = []
      normalized_target = target_gem_name.downcase

      Gem::Specification.each do |spec|
        spec.dependencies.each do |dep|
          dependents << [spec.name, dep.requirement.to_s] if dep.name.downcase == normalized_target
        end
      end

      dependents.sort_by(&:first)
    end

    # Finds all dependency chains leading to the target gem
    # @param target_gem_name [String] the gem to find chains for
    # @return [Array<Array<Hash>>] array of dependency chains
    def find_dependency_chains(target_gem_name)
      chains = []
      normalized_target = target_gem_name.downcase

      Gem::Specification.each do |spec|
        paths = find_paths_to_target(spec.name, normalized_target, [])
        chains.concat(paths)
      end

      chains.uniq.sort_by { |chain| chain.first[:name] }
    end

    private

    # Recursively finds all paths from current gem to target gem
    # @param current_gem [String] the current gem being explored
    # @param target_gem [String] the gem we're searching for
    # @param path [Array<Hash>] the current dependency path
    # @param visited [Set<String>] set of already visited gems (prevents cycles)
    # @return [Array<Array<Hash>>] array of paths to the target
    def find_paths_to_target(current_gem, target_gem, path, visited = Set.new)
      return [] if visited.include?(current_gem)

      visited = visited.dup
      visited.add(current_gem)
      spec = load_gem_spec(current_gem)
      return [] unless spec

      collect_dependency_paths(spec, target_gem, path, visited)
    end

    def collect_dependency_paths(spec, target_gem, path, visited)
      paths = []

      spec.dependencies.each do |dep|
        new_node = build_dependency_node(spec, dep)
        paths.concat(process_dependency(dep, target_gem, path, new_node, visited))
      end

      paths
    end

    def process_dependency(dep, target_gem, path, new_node, visited)
      if dep.name.downcase == target_gem.downcase
        [path + [new_node]]
      else
        find_paths_to_target(dep.name, target_gem, path + [new_node], visited)
      end
    end

    def load_gem_spec(gem_name)
      Gem::Specification.find_by_name(gem_name)
    rescue Gem::MissingSpecError
      nil
    end

    def build_dependency_node(spec, dep)
      name = spec.name
      version = spec.version.to_s
      dependency = dep.name
      requirement = dep.requirement.to_s
      { name:, version:, dependency:, requirement: }
    end
  end
end
