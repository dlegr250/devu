# frozen_string_literal: true

# No more requiring files manually, Zeitwerk autoloads everything
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module Devu
end
