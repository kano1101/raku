require 'csv'

class CsvWriter
  def self.to_num(str_or_int)
    if /^\d+$/ =~ str_or_int
      str_or_int = str_or_int.to_i
    end
    str_or_int
  end
  def self.generate_csv(items)
    CSV.open('item_contents.csv', 'w') do |csv|
      column_label = items[0].map do |key, value|
        key
      end
      csv << column_label
      items.each do |item|
        row = item.map do |key, value|
          value
        end
        csv << row 
      end
    end
  end
  def self.restore_csv
    items = []
    CSV.foreach('item_contents.csv', headers: true) do |row|
      items << row.map { |element| [element[0], to_num(element[1])] }.to_h
    end
    items
  end
end
