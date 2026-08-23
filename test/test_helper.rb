# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "simplecov"
SimpleCov.start do
  skip "/test/"
end

require "minitest/autorun"
require "mocha/minitest"
