# coding: utf-8
require 'watir'
require_relative 'flow'

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
      sleep(1)
      if getch then finish_program end
      if self.is_finishing then break end
      if Time.now >= time then break end
    end
  end
  def initialize
    set = YAML.load_file('settings.yml')
    @wait_sec = set['delay'].map do |scene_key, min_max_hash|
      [scene_key, min_max_hash]
    end.to_h
    @do_or_not_download = set['download']
    puts '設定ファイルを読み込みました。'
  end
  
  def do_scrape
    # print 'ラクマページよりCSVへとデータを落しますか？ (\'y\' or other) : '
    # do_or_not_download = gets.chomp
    Flow.download_and_generate_csv if @do_or_not_download == 'y'
  end
  def do_relist
    Flow.restore_csv_and_relist
  end

  def self.scrape
    unless $main
      puts 'プログラムを開始しました。'
      $main = Main.new
      $main.do_scrape
      puts 'プログラムを終了します。'
    end
  end
  def self.relist
    unless $main
      puts 'プログラムを開始しました。'
      $main = Main.new
      $main.do_relist
      puts 'プログラムを終了します。'
    end
  end
end
