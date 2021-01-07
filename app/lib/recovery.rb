# coding: utf-8
require_relative 'csv_writer'

class Recovery

  private
  
  def self.setup
    print '消える前のファイル名を入力してください。: '
    before_fnm = gets.chomp
    print '現在のファイル名を入力してください。: '
    after_fnm = gets.chomp
    
    @after_list = CsvWriter.restore_csv_with_name(after_fnm)
    @before_list = CsvWriter.restore_csv_with_name(before_fnm)
  end

  public
  
  def self.do_exclusive_or
    self.setup
    p CalcArray.diff_exclusive_or(@after_list, @before_list)
  end
  def self.do_regular_or
    self.setup
    p CalcArray.diff_regular_or(@after_list, @before_list)
  end
  
end

class CalcArray
  
  private

  KEYS = ['name', 'detail', 'category_id', 'size_id', 'brand_id', 'status',# 'sell_price',
          'carrieage', 'delivery_method', 'delivery_date', 'delivery_area', 'category_name', 'brand_name', 'request_required'].freeze
  
  def self.exclusive_or(a, b)
    (a | b) - (a & b)
  end
  def self.regular_or(a, b)
    a - b
  end

  def self.record_slice(list, keys)
    list.map do |record|
      record.slice(*keys)
    end
  end

  public
  
  # 全リストの重複がなかったレコードのみを抽出し戻り値とする
  def self.diff_exclusive_or(a, b)
    sliced_a = self.record_slice(a, KEYS)
    sliced_b = self.record_slice(b, KEYS)
    self.exclusive_or(sliced_a, sliced_b) # 配列間の排他的論理和が返る
  end
  def self.diff_regular_or(a, b)
    sliced_a = self.record_slice(a, KEYS)
    sliced_b = self.record_slice(b, KEYS)
    self.regular_or(sliced_a, sliced_b) # 配列間の差集合(a - b)が返る
  end
  
end
