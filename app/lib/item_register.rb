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
    RakumaBrowser.wait_page_load_complete(browser)
    scan_id_array = browser.html.scan(/gaConfirm\('(.+?)'\);/).map { |wrapped| wrapped[0] }
    id = item['id'].to_s
    match_index(scan_id_array, id)
  end

  # このメソッドで、商品削除に失敗してしまったかどうかを確認できる
  def self.is_item_deleted(browser)
    # 成功していたら/<title>出品した商品｜ラクマ<\/title>/がマッチする
    /<title>404  | お探しのページは見つかりませんでした<\/title>/ =~ browser.html
  end
  
  # 商品が存在しない(売れたまたは削除された)場合やidxが不正であればfalseを返すので、スキップ対応してください
  # idxに整数以外を入れると動作しません
  def self.delete(browser, item, idx)
    p 'idx = ' + idx.to_s
    return false unless idx
    # TODO : タイムアウトエラーの原因はここなので、次回にはつぶします
    p 'f1' + browser.alert.present?.to_s
    browser.a(id: 'ga_click_delete', index: idx).fire_event :onclick
    p 'torf2' + browser.alert.present?.to_s
    # TODO : ここでタイムアウトエラーの例外が発生することがある
    # おそらく一個前のa#fire_event :onclickの実行が、ページに表示がされるより前に実行されてしまったことによりそう
    al = browser.alert
    begin
      waiting_al = al.wait_until(timeout: 30, &:present?)
    rescue
      p 'my timeout'
      raise
    end
    p 't3' + browser.alert.present?.to_s
    p waiting_al.ok # ページの遷移先の<title>タグを見ると成功したかがわかる
    p 'f4' + browser.alert.present?.to_s
    return nil if self.is_item_deleted(browser) # <title>タグを確認し、削除失敗ならfalseを返す
    true
  end

  def self.exe_query_selector(browser, input_or_select, item_key, item)
    browser.execute_script(%!document.querySelector('%s[name="item[%s]"]').value='%s'! % [input_or_select, item_key, item[item_key]])
  end

  def self.wait_and_button_click(browser, word, item)
    # ここに入る前にScheduler.add_scheduleによってitem['confirm']とitem['submit']にTimeオブジェクトが追加されてある
    $main.wait_a_minute(browser, word, item)
    browser.button(:id => word).click
    begin
      browser.wait_while(timeout: 3600) { |b| b.button(:id => word).present? }
    rescue Watir::Wait::TimeoutError => e
      p e.class
      p e.message
      p word
      p item
      # binding.pry
      raise
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
    items.each do |item|
      self.exit_if_finishing

      # TODO : 仕様確認
      # browser.html =~ /<title>(.+?)<\/title>/
      # p '出品したページに入る前の状態(出品した商品でなければOK) : ' + Regexp.last_match(0).to_s
      
      # 「出品した商品」ページを開いて
      RakumaBrowser.goto_sell(browser)
      # ページの評価が早すぎて古いページを評価してしまう可能性がある問題をつぶす
      # RakumaBrowser.wait_sell_page_starting(browser)
      browser.wait # 成功で出品した商品に入るのでもうこれにする
      # 古いページを抜けたらページが完全に読み込まれるまで一旦待機する
      RakumaBrowser.wait_page_load_complete(browser)

      # 「続きを見る」全展開する
      RakumaBrowser.next_button_all_open(browser)

      # itemの再出品
      # TODO : 処理速度によっては（仮定ではあるが全展開が問題を生んで）「出品したページ」がロード中になったかもしれないのでつぶしたい
      RakumaBrowser.wait_page_load_complete(browser) # ここでそれをつぶすことにしている（本当に大丈夫なのか？）
      # browser.wait # ブラウザが遅いため待つ（結局こっちにしてみた 。）
      
      idx = self.item_index(browser, item) # リストにない場合はnilが返る（内部的にはArray#index仕様による）
      browser.div(id: 'selling-container').div(class: 'media', index: idx).scroll.to
      p '(self.item_indexの結果)idx = ' + idx.to_s
      
      case self.delete(browser, item, idx) # 普通に削除（ただしidxはロード済みでなくてはならない。正の整数を入れること）
      # 結果によってはユーザーが意図的に商品を削除したか、プログラム実行時点ですでに売れた場合が考えられる
      when nil
        puts "失敗nil (#{items.index(item) + 1}/#{items.count}): [" + item['name'] + "]の商品の再出品を試みましたが売れたまたはすでに削除されていました。"
      when false
        puts "失敗false (#{items.index(item) + 1}/#{items.count}): [" + item['name'] + "]の商品の再出品を試みましたがリストにないため削除できませんでした。"
      else
        RakumaBrowser.goto_new(browser)
        self.regist(browser, item)
        puts "成功 (#{items.index(item) + 1}/#{items.count}): [" + item['name'] + "]の再出品が完了しました。"
      end
    end
  end
  
end
