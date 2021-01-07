# coding: utf-8
require 'csv'

class CsvWriter
  DIR = 'csv/'
  NEW_FILE = DIR + 'item_contents.csv'
  def self.to_num(str_or_int)
    if /^\d+$/ =~ str_or_int
      str_or_int = str_or_int.to_i
    end
    str_or_int
  end
  def self.generate_csv(items)
    CSV.open(NEW_FILE, 'w') do |csv|
      column_label = items[0].map { |key, value| key }
      csv << column_label
      items.each do |item|
        row = item.map { |key, value| value }
        csv << row
      end
    end
    bk_fnm = DIR + Date.today.strftime('%Y%m%d') + Time.now.strftime('%H%M%S') + 'bk.csv'
    FileUtils.cp(NEW_FILE, bk_fnm)
  end
  def self.restore_csv
    self.restore_csv_with_name(NEW_FILE)
  end
  def self.restore_csv_with_name(fnm)
    puts "CSVファイルが存在しません。ファイル名 : #{fnm}" unless File.exists?(fnm)
    CSV.foreach(fnm, headers: true).map do |row|
      row.map { |element| [element[0], to_num(element[1])] }.to_h
    end
  end
end
