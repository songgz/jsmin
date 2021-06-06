require "jsmin/version"
require 'jsmin/compressor'

module Jsmin
  class Error < StandardError; end
  def js_min(in_device = $stdin, out_device = $stdout)
    j = Compressor.new(in_device, out_device)
    j.js_min
  end
end
