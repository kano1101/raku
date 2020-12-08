# coding: utf-8
require 'watir'
require_relative 'flow'

class Main
  def wait_a_minute(type_symbol)
    random = Random.new()
    time = random.rand(@wait_sec[type_symbol][:min]..@wait_sec[type_symbol][:max])
    puts '待ち:' + time.to_s + '秒' if 10.0 < time
    # begin
    browser.wait_until(time)
    # rescue Watir::Wait::TimeoutError
    # end
  end
  def initialize
    puts '設定ファイルを読み込みます。'
    set = YAML.load_file('settings.yml')
    @wait_sec = set['delay'].map do |scene_key, min_max_hash|
      [scene_key, min_max_hash]
    end.to_h
    # binding.pry
    # @wait_sec = {
    #   goto: { min: set['delay']['goto']['min'], max: set['delay']['goto']['max'] },
    #   dele: { min: set['delay']['dele']['min'], max: set['delay']['dele']['max'] },
    #   list: { min: set['delay']['list']['min'], max: set['delay']['list']['max'] },
    #   prop: { min: set['delay']['prop']['min'], max: set['delay']['prop']['max'] },
    #   imgs: { min: set['delay']['imgs']['min'], max: set['delay']['imgs']['max'] },
    #   othr: { min: set['delay']['othr']['min'], max: set['delay']['othr']['max'] },
    # }
    pp @wait_sec
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
