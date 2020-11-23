# coding: utf-8
require 'watir'
require_relative 'rakuma_browser'
require_relative 'item_scraper'
require_relative 'csv_writer'

class Flow
  def self.download_and_generate_csv
    browser = RakumaBrowser.start_up
    items = ItemScraper.download(browser)
    RakumaBrowser.exit(browser)
    CsvWriter.generate_csv(items)
  end

  def self.restore_csv_and_relist
    items = CsvWriter.restore_csv
    puts 'CSVファイルを読み込みました。'
    browser = RakumaBrowser.start_up
    puts '再出品用ブラウザ起動しました。'
    ItemRegister.relist(browser, items)
    puts '再出品が完了するまでもうひと頑張り。（未完成）'
    RakumaBrowser.exit(browser)
    puts 'ブラウザを閉じました。'
  end
end
