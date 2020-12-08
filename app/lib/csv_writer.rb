require 'csv'

class CsvWriter
  DIR = 'csv/'
  NEW_FILE = DIR + 'item_contents.csv'
  # BAK_FILE = DIR + 'item_contentsw.csv'
  def self.to_num(str_or_int)
    if /^\d+$/ =~ str_or_int
      str_or_int = str_or_int.to_i
    end
    str_or_int
  end
  def self.generate_csv(items)
    CSV.open(NEW_FILE, 'w') do |csv|
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
  def self.site_updated_csv(id: ,updated:) # todo updating
    csv = CSV.table(NEW_FILE)
    csv.each do |row|
      row['site_updated'] = updated if row['id'] == id
    end
    # csvw = CSV.open(BAK_FILE,'wb')
    # csvw << csv.headers
    # csv.each do |row|
    #   csvw << row
    # end
    # FileUtils.rm(NEW_FILE)
    # FileUtils.mv(BAK_FILE, NEW_FILE)
  end
  def self.restore_csv
    items = []
    CSV.foreach(NEW_FILE, headers: true) do |row|
      items << row.map { |element| [element[0], to_num(element[1])] }.to_h
    end
    items
  end
end
