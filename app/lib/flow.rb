# coding: utf-8
require 'watir'
require_relative 'rakuma_browser'
require_relative 'item_scraper'
require_relative 'item_register'
require_relative 'csv_writer'
require_relative 'scheduler'

class Flow
  def self.download_and_generate_csv
    browser = RakumaBrowser.start_up
    puts '出品中データの取得を開始します。'
    items = ItemScraper.download(browser)
    puts "全#{items.count}商品が存在します。"
    puts '出品中データの取得が完了しました。'
    RakumaBrowser.exit(browser)
    CsvWriter.generate_csv(items)
    puts '取得したデータをCSVファイルに保存しました。'
  end

  def self.restore_csv_and_relist
    items = CsvWriter.restore_csv.reverse
    puts 'CSVファイルを読み込みました。'
    # TODO : Viewerで実行有無の調整をできるようにしたい
    items = Scheduler.add_schedule(items)
    Scheduler.print_schedule(items)
    puts 'スケジューリングを行いました。'
    browser = RakumaBrowser.start_up
    ItemRegister.relist(browser, items)
    puts 'すべて再出品が完了しました。'
    RakumaBrowser.exit(browser)
  end
end
