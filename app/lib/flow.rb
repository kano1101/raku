# coding: utf-8
require 'watir'
require_relative 'rakuma_browser'
require_relative 'item_scraper'
require_relative 'csv_writer'

class Flow
  def self.download_and_generate_csv
    puts 'ブラウザを起動します。'
    browser = RakumaBrowser.start_up
    puts '出品中データの取得を開始します。'
    items = ItemScraper.download(browser)
    puts '出品中データの取得が完了しました。'
    RakumaBrowser.exit(browser)
    puts '取得したデータをCSVファイルに保存します。'
    CsvWriter.generate_csv(items)
    puts '取得したデータをCSVファイルに保存しました。'
  end

  def self.restore_csv_and_relist
    puts 'CSVファイルを読み込みます。'
    items = CsvWriter.restore_csv
    puts 'CSVファイルを読み込みました。'
    browser = RakumaBrowser.start_up
    puts '再出品用ブラウザ起動しました。再出品を開始します。'
    ItemRegister.relist(browser, items)
    puts '再出品が完了しました。'
    RakumaBrowser.exit(browser)
    puts 'ブラウザを閉じました。'
  end
end
