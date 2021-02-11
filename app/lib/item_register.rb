# coding: utf-8
require 'watir'
require_relative 'main'
require_relative 'csv_writer'
require_relative 'rakuma_browser'
require_relative 'rblib/times_retry'

class ItemRegister

  using TimesRetry

  # 見つからなければnil
  def self.match_index(str_array, str)
    str_array.index { |e_str| e_str == str }
  end

  # idを見てに商品の位置を整数で返す
  # 入る前にページが完全にロードされた状態にしておいてください。
  def self.item_index(browser, item)
    scan_id_array = browser.html.scan(/gaConfirm\('(.+?)'\);/).map { |wrapped| wrapped[0] }
    id = item['id'].to_s
    match_index(scan_id_array, id)
  end

  def self.delete_failure?(browser)
    RakumaBrowser.wait(browser)
    /<title>404  | お探しのページは見つかりませんでした<\/title>/ =~ browser.html
  end
  
  def self.regist_failure?(browser)
    RakumaBrowser.wait(browser)
    /<title>出品する｜ラクマ<\/title>/ =~ browser.html
  end
  
  def self.exe_query_selector(browser, input_or_select, item_key, item)
    browser.execute_script(%!document.querySelector('%s[name="item[%s]"]').value='%s'! % [input_or_select, item_key, item[item_key]])
  end
  def self.exe_inner_text(browser, item_key, item)
    browser.execute_script(%!document.getElementById('%s').innerText = '%s'! % [item_key, item[item_key]]) # category_name
  end

  def self.wait_and_button_click(browser, word, item, retry_max = 10)
    # ここに入る前にScheduler.add_scheduleによってitem['confirm']とitem['submit']にTimeオブジェクトが追加されてある
    $main.wait_a_minute(browser, word, item)
    begin
      browser.button(id: word).click
      browser.wait_while(timeout: 60) { |b| b.button(id: word).present? }
    rescue
      puts "#{word}ボタン押下処理ミス"
      raise
    end
    RakumaBrowser.wait(browser)
  end
  
  # 商品が存在しない(売れたまたは削除された)場合はnil、idxが不正であればfalseを返すので、スキップ対応してください
  # idxに正の整数以外を入れると動作しません
  # 削除に成功するとtrueが返る
  def self.delete(browser, item, retry_max = 10)
    # 商品リストの展開とindex取得
    RakumaBrowser.goto_sell(browser)
    RakumaBrowser.open_list(browser)
    idx = item_index(browser, item)
    return nil unless idx

    # 再出品対象までスクロール
    target = browser.div(id: 'selling-container').divs(class: 'media')[idx]
    target.scroll.to

    # 削除
    browser.as(id: 'ga_click_delete')[idx].fire_event :onclick
    browser.alert.wait_until(timeout: 30, &:present?).ok # ページの遷移先の<title>タグを見ると成功したかがわかる
    RakumaBrowser.wait(browser)

    # 削除できたかチェック
    is_failure = self.delete_failure?(browser) # <title>タグを確認し、削除失敗ならfalseを返す
    return nil if is_failure

    # 削除成功
    true
  end

  def self.regist(browser, item)
    RakumaBrowser.goto_new(browser)

    # 画像情報の抽出
    img_files = item.find_all do |key, value|
      key.include?('img')
    end.map do |key, value|
      value
    end

    # 画像をセット
    count = img_files.compact.count
    for idx in 0...count do
      browser.file_field(id: 'image_tmp', index: idx).set(Dir.pwd + '/saved_img/' + img_files[idx])
    end

    # 各フォームへ値をセット
    browser.input(id: 'name').send_keys(item['name']) # name
    browser.textarea(id: 'detail').send_keys(item['detail']) # detail
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
    self.exe_inner_text(browser, 'category_name', item) # category_name
    # self.exe_inner_text(browser, 'size_name', item) unless item['size_id'] == 19999 # size_name # 不要
    self.exe_inner_text(browser, 'brand_name', item) # brand_name
    # delivery_method_name
    # related_size_group_ids
    self.exe_query_selector(browser, 'select', 'request_required', item)

    # 確認、出品するボタンの押下処理
    self.decide(browser, item)

    # 出品できたかチェック
    is_failure = self.regist_failure?(browser)
    return nil if is_failure

    # 出品成功
    true
  end

  def self.decide(browser, item)
    self.wait_and_button_click(browser, 'confirm', item)
    self.wait_and_button_click(browser, 'submit', item)
  end
  
  def self.already_deleted?(browser, item)
    RakumaBrowser.goto_sell(browser)
    RakumaBrowser.open_list(browser)
    idx = self.item_index(browser, item)
    !idx
  end

  def self.already_registed?(browser, item)
    RakumaBrowser.goto_sell(browser)
    first_item_title = browser.div(id: 'selling-container').divs(class: 'media').first.element(class: 'media-heading').text
    is_already = item['name'] == first_item_title
    is_already
  end
  
  def self.exit_if_finishing
    if $main.is_finishing
      puts 'プログラムを途中終了します。'
      exit
    end
  end

  def self.relist(browser, items, retry_max = 10)
    puts '正しく終了する場合はEnterキーを押して少しお待ちください。'
    
    items.each.with_index do |item, n|
      
      # 中断したい場合
      self.exit_if_finishing

      # 商品削除
      delete_status = false
      retry_max.times_retry do
        begin
          delete_status = self.delete(browser, item)
        rescue
          break if self.already_deleted?(browser, item)
          raise
        end
      end

      # リストにそもそも存在しなかったら出品処理しない
      unless delete_status
        puts "削除失敗   : (#{n}/#{items.count + 1}) : [#{item['name']}]"
        next
      end

      # 再出品実行
      retry_max.times_retry do
        begin
          regist_status = self.regist(browser, item)
          raise RuntimeError, '出品に失敗しましたアラート発生' unless regist_status
        rescue
          break if self.already_registed?(browser, item) # 成功ならエラーながらに再出品自体はうまくいっているのでリトライしない
          raise
        end
      end

      puts "再出品成功 : (#{n}/#{items.count + 1}) : [#{item['name']}]"
      
    end # items.each do
  end # def self.relist
end
