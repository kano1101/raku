# coding: utf-8
require 'watir'
require_relative 'main'
require_relative 'csv_writer'
require_relative 'rakuma_browser'

class ItemRegister
  
  def self.match_index(str_array, str)
    str_array.index { |e_str| e_str == str }
  end
  
  # 念のため入る前にページが完全にロードされた状態にしておいてください。
  def self.item_index(browser, item)
    # RakumaBrowser.wait_page_load_complete(browser)
    scan_id_array = browser.html.scan(/gaConfirm\('(.+?)'\);/).map { |wrapped| wrapped[0] }
    id = item['id'].to_s
    match_index(scan_id_array, id)
  end

  def self.is_item_deleted(browser)
    /<title>404  | お探しのページは見つかりませんでした<\/title>/ =~ browser.html
  end
  
  # 商品が存在しない(売れたまたは削除された)場合はnil、idxが不正であればfalseを返すので、スキップ対応してください
  # idxに正の整数以外を入れると動作しません
  def self.delete(browser, item, idx)
    return false unless idx
    retry_count = 0
    retry_max = 5
    begin
      browser.a(id: 'ga_click_delete', index: idx).fire_event :onclick
      browser.alert.wait_until(timeout: 30, &:present?).ok # ページの遷移先の<title>タグを見ると成功したかがわかる
    rescue Watir::Wait::TimeoutError => e
      retry_count += 1
      if retry_count <= retry_max
        puts "削除処理タイムアウトretryします。(#{retry_count}回目)"
        retry
      else
        p '削除処理でタイムアウトエラーが発生しました。'
        p e.class
        p e.message
        raise
      end
    rescue Watir::Exception::UnknownObjectException => e
      retry_count += 1
      if retry_count <= retry_max
        puts "削除処理未知のエラーretryします。(#{retry_count}回目)"
        retry
      else
        p '削除処理で未知のエラーが発生しました。'
        p e.class
        p e.message
        raise
      end
    end
    retry_count = 0
    begin
      browser.wait
    rescue Watir::Wait::TimeoutError => e
      retry_count += 1
      if retry_count <= retry_max
        puts "削除処理後のwaitでタイムアウトretryします。(#{retry_count}回目)"
        retry
      else
        p '削除処理後のwaitでタイムアウトエラーが発生しました。'
        p e.class
        p e.message
        raise
      end
    end
    return nil if self.is_item_deleted(browser) # <title>タグを確認し、削除失敗ならfalseを返す
    true
  end

  def self.exe_query_selector(browser, input_or_select, item_key, item)
    browser.execute_script(%!document.querySelector('%s[name="item[%s]"]').value='%s'! % [input_or_select, item_key, item[item_key]])
  end

  def self.wait_and_button_click(browser, word, item)
    # ここに入る前にScheduler.add_scheduleによってitem['confirm']とitem['submit']にTimeオブジェクトが追加されてある
    $main.wait_a_minute(browser, word, item)
    retry_count = 0
    begin
      browser.button(:id => word).click
      browser.wait_while(timeout: 60) { |b| b.button(:id => word).present? }
    rescue Watir::Wait::TimeoutError => e
      retry_count += 1
      if retry_count <= 3
        puts "#{word}:retryします。 (#{retry_count}回目)"
        retry
      else
        p 'ボタンの押下処理でエラーが発生しました。再出品が実行できているか確認してください。'
        p e.class
        p e.message
        p word
        p item
        raise
      end
    end
    browser.wait
  end
  
  def self.regist(browser, item)
    img_files = item.find_all do |key, value|
      key.include?('img')
    end.map do |key, value|
      value
    end
    count = img_files.compact.count
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

    self.wait_and_button_click(browser, 'confirm', item)
    self.wait_and_button_click(browser, 'submit', item)
  end
  
  def self.exit_if_finishing
    if $main.is_finishing
      puts 'プログラムを途中終了します。'
      exit
    end
  end

  def self.relist(browser, items)
    puts '正しく終了する場合はEnterキーを押して少しお待ちください。'
    
    # 「出品した商品」ページを開いて
    RakumaBrowser.goto_sell(browser)
    items.each do |item|
      # 中断したい場合
      self.exit_if_finishing

      # ページの評価が早すぎて古いページを評価してしまう可能性がある問題をつぶす
      RakumaBrowser.wait_sell_page_starting(browser)

      # 「続きを見る」全展開する
      RakumaBrowser.next_button_all_open(browser)

      # itemの再出品
      idx = self.item_index(browser, item) # リストにない場合はnilが返る（内部的にはArray#index仕様による）
      if idx
        target = browser.div(id: 'selling-container').div(class: 'media', index: idx)
        target.scroll.to
        # deleteした結果がうまくいったかで既削除、売れ済を判断できる
        if self.delete(browser, item, idx) # 普通に削除（ただしidxはロード済みでなくてはならない。正の整数を入れること）
          RakumaBrowser.goto_new(browser)
          retry_count = 0
          begin
            self.regist(browser, item)
          rescue Watir::Exception::ObjectDisabledException => e
            retry_count += 1
            if retry_count <= 3
              puts "出品するボタンの押下タイムアウト:retryします。 (#{retry_count}回目)"
              RakumaBrowser.exit(browser)
              browser = RakumaBrowser.start_up
              RakumaBrowser.goto_new(browser)
              retry
            else
              p '出品するボタンの押下処理でエラーが発生しました。再出品が実行できているか確認してください。'
              p e.class
              p e.message
              raise
            end
          end      
          puts "成功 (#{items.index(item) + 1}/#{items.count}): [" + item['name'] + "]の再出品が完了しました。"
          RakumaBrowser.goto_sell(browser)
        else
          puts "skip (#{items.index(item) + 1}/#{items.count}): [" + item['name'] + "]の商品の再出品を試みましたが売れたまたはすでに削除されていました。"
        end
      else
        puts "失敗 (#{items.index(item) + 1}/#{items.count}): [" + item['name'] + "]の商品の再出品を試みましたがリストにないため削除できませんでした。"
      end
    end
  end
  
end
