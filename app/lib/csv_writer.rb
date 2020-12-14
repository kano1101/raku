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
    items = []
    CSV.foreach(NEW_FILE, headers: true) do |row|
      items << row.map { |element| [element[0], to_num(element[1])] }.to_h
    end
    items
  end
end
