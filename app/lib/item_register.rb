# coding: utf-8
require 'watir'
require_relative 'main'
require_relative 'csv_writer'
require_relative 'rakuma_browser'

class ItemRegister
  def self.match_index(str_array, str)
    str_array.index { |e_str| e_str == str }
  end
  def self.find_scroll_locate(browser, item)
    scan_id_array = browser.html.scan(/gaConfirm\('(.+?)'\);/).map { |wrapped| wrapped[0] }
    id = item['id'].to_s
    match_index(scan_id_array, id)
  end

  def self.delete(browser, item)
    idx = self.find_scroll_locate(browser, item)
    if idx
      $main.wait_a_minute(browser, 'dele', item)
      browser.a(id: 'ga_click_delete', index: idx).fire_event :onclick
      browser.alert.wait_until(&:present?).ok
      browser.wait
    end
    idx
  end

  def self.exe_query_selector(browser, input_or_select, item_key, item)
    browser.execute_script(%!document.querySelector('%s[name="item[%s]"]').value='%s'! % [input_or_select, item_key, item[item_key]])
  end
  
  def self.regist(browser, item)
    img_files = item.find_all do |key, value|
      key.include?('img')
    end.map do |key, value|
      value
    end
    count = img_files.count { |n| n }
    for idx in 0...count do
      browser.file_field(id: 'image_tmp', index: idx).set(Dir.pwd + '/saved_img/' + img_files[idx])
    end
    
    browser.input(:id => 'name').send_keys(item['name']) # name
    browser.textarea(:id => 'detail').send_keys(item['detail']) # detail
    # parent_category_id
    self.exe_query_selector(browser, 'input', 'category_id', item)
    unless item['size_id'] == 19999 # size_id
      browser.execute_script <<~JS
        function make_hidden(name, value) {
          var q = document.createElement('input');
          q.type = 'hidden';
          q.name = name;
          q.value = value;
          var hidden_category_el = document.getElementsByName('item[category_id]');
          hidden_category_el[0].after(q);
        }
        make_hidden('item[size_id]', '#{item['size_id']}');
      JS
      self.exe_query_selector(browser, 'input', 'size_id', item)
    end
    self.exe_query_selector(browser, 'input', 'brand_id', item)
    # informal_brand_id
    self.exe_query_selector(browser, 'select', 'status', item)
    # origin_price
    self.exe_query_selector(browser, 'input', 'sell_price', item)
    # transaction_status
    self.exe_query_selector(browser, 'select', 'carriage', item)
    self.exe_query_selector(browser, 'input', 'delivery_method', item)
    self.exe_query_selector(browser, 'select', 'delivery_date', item)
    self.exe_query_selector(browser, 'select', 'delivery_area', item)
    # open_flag
    # sold_out_flag
    # created_at
    # updated_at
    browser.execute_script(%!document.getElementById('category_name').innerText = "#{item['category_name']}"!) # category_name
    # browser.execute_script(%!document.getElementById('size_name').innerText = "#{item['size_name']}"!) unless item['size_id'] == 19999 # size_name # 不要
    browser.execute_script(%!document.getElementById('brand_name').innerText = "#{item['brand_name']}"!) # brand_name
    # delivery_method_name
    # related_size_group_ids
    self.exe_query_selector(browser, 'select', 'request_required', item)
    
    $main.wait_a_minute(browser, 'list', item)
    browser.button(:id => 'confirm').click
    browser.wait_while { |b| b.button(:id => 'confirm').present? }
    
    $main.wait_a_minute(browser, 'othr', item)
    browser.button(:id => 'submit').click
    browser.wait_while { |b| b.button(:id => 'submit').present? }
  end
  
  def self.relist(browser, items)
    items.each do |item|
#      puts item['name'] + 'の再出品のための削除を行います。'
      RakumaBrowser.goto_sell(browser)
      if self.delete(browser, item)
        puts item['name'] + 'を削除しました。'
        RakumaBrowser.goto_new(browser)
        self.regist(browser, item)
        puts item['name'] + 'の再出品が完了しました。'
      else
        puts item['name'] + 'の削除を試みましたがリストにないため削除に失敗しました。'
      end
    end
  end
end
