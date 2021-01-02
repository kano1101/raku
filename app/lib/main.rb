# coding: utf-8
require 'watir'
require_relative 'flow'
require_relative 'yaml_util'

class Main
  def make_wait_time(scene)
    random = Random.new()
    random.rand(@wait_sec[scene]['min']..@wait_sec[scene]['max'])
  end
  def getch
    system("stty raw -echo")
    char = STDIN.read_nonblock(1) rescue nil
    system("stty -raw echo")
    print char
    char
  end
  def initialize
    @is_finishing = false
  end

  private
  def finish_program
    @is_finishing = true
  end
  public

  attr_reader :is_finishing
  
  def wait_a_minute(scene, item)
    time = item[scene]
    loop do
      p time
      p item
      sleep(1)
      if getch then finish_program end
      if self.is_finishing then break end
      if Time.now >= time then break end
    end
  end
  def initialize
    delays = YamlUtil.new.read
    @wait_sec = {
      'confirm' => { 'min' => delays['conmin'], 'max' => delays['conmax'] },
      'submit'  => { 'min' => delays['submin'], 'max' => delays['submax'] },
    }
    # @wait_sec = set['delay'].map do |scene_key, min_max_hash|
    #   [scene_key, min_max_hash]
    # end.to_h
    puts '設定ファイルを読み込みました。'
  end
  
  def self.scrape
    Flow.download_and_generate_csv
  end
  def self.relist
    puts 'Main#relist'
    Flow.restore_csv_and_relist
  end
end
