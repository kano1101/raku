require 'tk'
require_relative 'csv_writer'
require_relative 'main'

$main = Main.new

class RelistTester
  def self.test
    Main.relist
  end
end
