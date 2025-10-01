# frozen_string_literal: true

require "rainbow"

module GemWhy
  module Formatters
    # Base formatter with colorization support
    class BaseFormatter
      attr_reader :command

      def initialize(command)
        @command = command
      end

      private

      # Determines if output should be colorized
      # @return [Boolean] true if colors should be used
      def colorize?
        !command.options[:no_color] && $stdout.tty?
      end

      # Colorizes text if appropriate
      # @param text [String] the text to colorize
      # @param color [Symbol] the color to apply
      # @return [String] the colorized or original text
      def colorize(text, color)
        colorize? ? Rainbow(text).color(color) : text
      end

      # Delegates to command's say method
      def say(message)
        command.say(message)
      end
    end
  end
end
