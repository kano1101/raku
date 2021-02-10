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

  def self.is_item_deleted(browser)
    /<title>404  | お探しのページは見つかりませんでした<\/title>/ =~ browser.html
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
      puts "#{word}ボタン押下処理実行"
      raise
    end
    RakumaBrowser.wait(browser)
  end
  
  # 商品が存在しない(売れたまたは削除された)場合はnil、idxが不正であればfalseを返すので、スキップ対応してください
  # idxに正の整数以外を入れると動作しません
  # 削除に成功するとtrueが返る
  def self.delete(browser, idx, retry_max = 10)
    return false unless idx
    retry_max.times_retry do
      browser.a(id: 'ga_click_delete', index: idx).fire_event :onclick
      browser.alert.wait_until(timeout: 30, &:present?).ok # ページの遷移先の<title>タグを見ると成功したかがわかる
    end
    RakumaBrowser.wait(browser)
    return nil if self.is_item_deleted(browser) # <title>タグを確認し、削除失敗ならfalseを返す
    true
  end

  def self.regist(browser, item)

    script_parts = [
      { type: 'input'  , key: 'category_id' },
      { type: 'input'  , key: 'brand_id' },
      { type: 'select' , key: 'status' },
      { type: 'input'  , key: 'sell_price' },
      { type: 'select' , key: 'carriage' },
      { type: 'input'  , key: 'delivery_method' },
      { type: 'select' , key: 'delivery_data' },
      { type: 'select' , key: 'delivery_area' },
      { type: 'select' , key: 'request_required' },
    ]

    RakumaBrowser.goto_new(browser)

    img_files = item.find_all do |key, value|
      key.include?('img')
    end.map do |key, value|
      value
    end

    count = img_files.compact.count
    for idx in 0...count do
      browser.file_field(id: 'image_tmp', index: idx).set(Dir.pwd + '/saved_img/' + img_files[idx])
    end

    browser.input(id: 'name').send_keys(item['name']) # name
    browser.textarea(id: 'detail').send_keys(item['detail']) # detail
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

    script_parts.each do |part|
      self.exe_query_selector(browser, part[:type], part[:key], item)
    end

    self.exe_inner_text(browser, 'category_name', item) # category_name
    self.exe_inner_text(browser, 'brand_name', item) # brand_name
    
    self.decide(browser, item)
  end

  def self.decide(browser, item)
    self.wait_and_button_click(browser, 'confirm', item)
    self.wait_and_button_click(browser, 'submit', item)
  end
  
  def self.not_deleted?(browser, item)
    RakumaBrowser.goto_sell(browser)
    idx = self.open_list_and_get_item_index(browser, item)
    !!idx
  end

  def self.not_registed?(browser, item)
    RakumaBrowser.goto_sell(browser)
    first_item_title = browser.div(id: 'selling-container').divs(class: 'media').first.element(class: 'media-heading').text
    is_already = item['name'] == first_item_title
    !is_already
  end
  
  def self.open_list_and_get_item_index(browser, item)
    RakumaBrowser.goto_sell(browser)
    # ページの評価が早すぎて古いページを評価してしまう可能性がある問題をつぶす
    RakumaBrowser.wait_sell_page_starting(browser)
    # 「続きを見る」全展開する
    RakumaBrowser.next_button_all_open(browser)
    idx = self.item_index(browser, item) # リストにない場合はnilが返る（内部的にはArray#index仕様による）
    idx
  end

  def self.exit_if_finishing
    if $main.is_finishing
      puts 'プログラムを途中終了します。'
      exit
    end
  end

  def self.relist(browser, items, retry_max = 10)
    puts '正しく終了する場合はEnterキーを押して少しお待ちください。'
    
    items.each do |item|
      
      # 中断したい場合
      self.exit_if_finishing

      # 商品リストの展開とindex取得
      idx = self.open_list_and_get_item_index(browser, item)
      unless idx
        puts "商品が存在しません。[#{item['name']}]"
        next
      end

      # 再出品対象までスクロール
      target = browser.div(id: 'selling-container').divs(class: 'media')[idx]
      target.scroll.to
      
      # 商品削除
      retry_max.times_retry do
        if self.not_deleted?(browser, item)
          self.delete(browser, idx)
        end
      end

      # 再出品実行
      retry_max.times_retry do
        if self.not_registed?(browser, item) # 成功ならエラーながらに再出品自体はうまくいっているのでリトライしない
          self.regist(browser, item)
        end
      end

      puts "再出品成功 : [#{item['name']}]"

    end # items.each do
  end # def self.relist
end
