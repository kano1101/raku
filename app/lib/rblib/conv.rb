#!/usr/bin/env ruby

module Convertable
  refine Time do
    def to_str
      itself.strftime('%F %H:%M:%S').to_s
    end
  end
  refine String do
    def to_time
      Time.new(*itself.scan(/\d+/))
    end
  end
end

using Convertable
