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

  def self.exe_query_selector(browser, input_or_select, item_key, item)
    browser.execute_script(%!document.querySelector('%s[name="item[%s]"]').value='%s'! % [input_or_select, item_key, item[item_key]])
  end
  
  def self.delete(browser, item)
    idx = self.find_scroll_locate(browser, item)
    $main.wait_a_minute(browser, 'dele')
    if idx
      browser.a(id: 'ga_click_delete', index: idx).fire_event :onclick
      browser.alert.wait_until(&:present?).ok
    end
    idx
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
    browser.execute_script(%!document.querySelector('input[name="item[category_id]"]').value='%s'! % item['category_id']) # category_id
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
    end
    browser.execute_script(%!document.querySelector('input[name="item[size_id]"]').value='%s'! % item['size_id']) # size_id
    browser.execute_script(%!document.querySelector('input[name="item[brand_id]"]').value='%s'! % item['brand_id']) # brand_id
    # informal_brand_id
    browser.execute_script(%!document.querySelector('select[name="item[status]"]').value='%s'! % item['status']) # status
    # origin_price
    browser.execute_script(%!document.querySelector('input[name="item[sell_price]"]').value='%s'! % item['sell_price']) # sell_price
    # transaction_status
    browser.execute_script(%!document.querySelector('select[name="item[carriage]"]').value='%s'! % item['carriage']) # carriage
    browser.execute_script(%!document.querySelector('input[name="item[delivery_method]"]').value='%s'! % item['delivery_method']) # delivery_method
    browser.execute_script(%!document.querySelector('select[name="item[delivery_date]"]').value='%s'! % item['delivery_date']) # delivery_date
    browser.execute_script(%!document.querySelector('select[name="item[delivery_area]"]').value='%s'! % item['delivery_area']) # delivery_area
    # open_flag
    # sold_out_flag
    # created_at
    # updated_at
    browser.execute_script(%!document.getElementById('category_name').innerText = "#{item['category_name']}"!) # category_name
    # browser.execute_script(%!document.getElementById('size_name').innerText = "#{item['size_name']}"!) unless item['size_id'] == 19999 # size_name # 不要
    browser.execute_script(%!document.getElementById('brand_name').innerText = "#{item['brand_name']}"!) # brand_name
    # delivery_method_name
    # related_size_group_ids
    browser.execute_script(%!document.querySelector('select[name="item[request_required]"]').value='%s'! % item['request_required']) # request_required
    
    $main.wait_a_minute(browser, 'list')
    browser.button(:id => 'confirm').click
    $main.wait_a_minute(browser, 'othr')
    browser.button(:id => 'submit').click
  end
  
  def self.relist(browser, items)
    items.reverse.each do |item|
      puts item['name'] + 'の再出品のための削除を行います。'
      RakumaBrowser.goto_sell(browser)
      if self.delete(browser, item)
        RakumaBrowser.goto_new(browser)
        self.regist(browser, item)
        puts item['name'] + 'の再出品が完了しました。'
      elsif
        puts item['name'] + 'の削除を試みましたがリストにないため失敗しました。'
      end
    end
  end
end
