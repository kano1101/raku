# coding: utf-8
require 'watir'
require_relative 'yaml_util'
require_relative 'rakuma_browser'
require_relative 'item_scraper'
require_relative 'item_register'
require_relative 'item_selector'
require_relative 'scheduler'
require_relative 'csv_writer'

class Main
  def make_wait_time(scene)
    random = Random.new()
    random.rand(@wait_sec[scene]['min'].to_f..@wait_sec[scene]['max'].to_f)
  end
  def getch
    system("stty raw -echo")
    char = STDIN.read_nonblock(1) rescue nil
    system("stty -raw echo")
    char
  end

  def start_relister
    delays = YamlUtil.new.read
    @wait_sec = {
      'confirm' => { 'min' => delays['conmin'], 'max' => delays['conmax'] },
      'submit'  => { 'min' => delays['submin'], 'max' => delays['submax'] },
    }
    puts 'スケジューリング設定値を読み込みました。'
    
    @is_finishing = false
    puts '再出品を開始します。'
  end
  
  def finish_relister
    puts '再出品を終了します。'
    @is_finishing = true
  end

  def initialize
    @is_finishing = true
  end
  
  attr_reader :is_finishing
  
  def wait_a_minute(browser, scene, item)
    time = item[scene]
    loop do
      sleep(1)
      finish_relister if getch
      break if is_finishing or Time.now >= time
    end
  end
  
  def self.scrape
    browser = RakumaBrowser.start_up
    puts '出品中データの取得を開始します。'
    items = ItemScraper.download(browser)
    puts "全#{items.count}商品が存在します。"
    puts '出品中データの取得が完了しました。'
    RakumaBrowser.exit(browser)
    CsvWriter.generate_csv(items.reverse)
    puts '取得したデータをCSVファイルに保存しました。'
  end
  def self.relist
    $main.start_relister
    items = CsvWriter.restore_csv
    puts 'CSVファイルを読み込みました。'
    # TODO : Viewerで実行有無の調整をできるようにしたい
    items = Scheduler.add_schedule(items)
    Scheduler.print_schedule(items)
    puts 'スケジューリングを行いました。'
    browser = RakumaBrowser.start_up
    ItemRegister.relist(browser, items)
    puts 'すべて再出品が完了しました。'
    RakumaBrowser.exit(browser)
    $main.finish_relister
  end
  def self.select
    items = CsvWriter.restore_csv
    puts 'CSVファイルを読み込みました。'
    ItemSelector.new(items)
    CsvWriter.generate_csv(items)
    puts '再出品の可否をCSVファイルに追加しました。'
  end
end
