# coding: utf-8
require 'watir'
require_relative 'flow'

class Main
  def make_wait_time(scene)
    random = Random.new()
    random.rand(@wait_sec[scene]['min']..@wait_sec[scene]['max'])
  end
  def wait_a_minute(browser, scene, item)
    time = item[scene]
    browser.wait_until(timeout: 600) { Time.now >= time }
  end
  def initialize
    set = YAML.load_file('settings.yml')
    @wait_sec = set['delay'].map do |scene_key, min_max_hash|
      [scene_key, min_max_hash]
    end.to_h
    @do_or_not_download = set['download']
    puts '設定ファイルを読み込みました。'
  end
  
  def main
    # print 'ラクマページよりCSVへとデータを落しますか？ (\'y\' or other) : '
    # do_or_not_download = gets.chomp
    puts 'プログラムを開始しました。'
    Flow.download_and_generate_csv if @do_or_not_download == 'y'
    Flow.restore_csv_and_relist
    puts 'CSVファイル分の再出品が完了しました。'
  end

  def self.run
    unless $main
      $main = Main.new
      $main.main
    end
  end
end

if __FILE__ == $0
  Main.run
end
