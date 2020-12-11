# coding: utf-8
require 'watir'
require_relative 'flow'

class Main
  def wait_a_minute(browser, scene)
    random = Random.new()
    time = random.rand(@wait_sec[scene]['min']..@wait_sec[scene]['max'])
    puts '待ち:' + time.to_s + '秒' # if 10.0 < time
    sleep time
  end
  def initialize
    puts '設定ファイルを読み込みます。'
    set = YAML.load_file('settings.yml')
    @wait_sec = set['delay'].map do |scene_key, min_max_hash|
      [scene_key, min_max_hash]
    end.to_h
  end
  
  def main
    print 'ラクマページよりCSVへとデータを落しますか？ (\'y\' or other) : '
    do_or_not_download = gets.chomp
    Flow.download_and_generate_csv if do_or_not_download == 'y'
    puts 'CSVファイルから再出品を開始します。'
    Flow.restore_csv_and_relist
    puts 'すべての再出品が完了しました。'
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
