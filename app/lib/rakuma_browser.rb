# coding: utf-8
require 'yaml'
require 'watir'
require_relative 'main'
require_relative 'rblib/best'

class RakumaBrowser
  
  USER_DATA_DIR = %W[--user-data-dir=./UserData/]
  def self.wake_up
    # browser = Watir::Browser.new :chrome, switches: USER_DATA_DIR
    # goto_mypage(browser)
    # browser
    client = Selenium::WebDriver::Remote::Http::Default.new
    client.read_timeout = 600
    client.open_timeout = 600
    browser =  Watir::Browser.new :chrome, switches: USER_DATA_DIR, :http_client => client
    goto_mypage(browser)
    browser
  end
  
  def self.goto_url(browser, url)
    retry_count = 0
    begin
      browser.goto(url)
      begin
        browser.wait
      rescue Watir::Wait::TimeoutError
        retry
      end
    rescue Net::ReadTimeout => e
      retry_count += 1
      if retry_count <= 3
        puts "Net::ReadTimeoutエラー発生:retryします。（#{retry_count}回目）"
        retry
      else
        puts "Net::ReadTimeoutエラーで失敗。再出品が実行できているか確認してください。"
        p e.class
        p e.message
        raise
      end
    end
  end
  
  def self.goto_mypage(browser)
    mypage_url = 'https://fril.jp/mypage'
    goto_url(browser, mypage_url)
  end
  def self.goto_login(browser)
    login_url = 'https://fril.jp/users/sign_in'
    goto_url(browser, login_url)
  end
  def self.goto_sell(browser)
    sell_url = 'https://fril.jp/sell'
    goto_url(browser, sell_url)
  end
  def self.goto_new(browser)
    new_url = 'https://fril.jp/item/new'
    goto_url(browser, new_url)
  end

  def self.auto_close(browser)
    browser.close
  end
  def self.wait_close(browser)
    browser.wait_while(timeout: 3600, &:exists?)
    browser.close
  end
  
  def self.succeeded_login(browser)
    /<title>マイページ｜ラクマ<\/title>/ =~ browser.html
  end

  def self.start_up
    browser = wake_up
    unless self.succeeded_login(browser)
      # 一度目ならログインが必要であり、browserは更新される
      goto_login(browser)
      wait_close(browser) # 手動でブラウザが閉じられるのを待つ
      browser = wake_up
      raise 'ログインに失敗しました。' unless self.succeeded_login(browser)
    end
    puts 'ログイン成功'
    browser
  end

  def self.exit(browser)
    browser.close
  end

  def self.goto_url_by_new_tab(browser, url)
    browser.execute_script('window.open()')
    browser.windows.last.use
    self.goto_url(browser, url)
  end
  def self.close_last_tab(browser)
    browser.windows.last.close
  end

  def self.wait_sell_page_starting(browser)
    browser.wait_until(timeout: 3600) do
      browser.html =~ /<title>出品した商品｜ラクマ<\/title>/ # 表示がsell_pageとわかれば真が返るのでそうなれば次へ進むことができます
    end
  end

  def self.next_button_span(browser)
    browser.span(id: 'selling-container_button')
  end
  def self.next_button_anchor(browser)
    self.next_button_span(browser).a(index: 0)
  end
  def self.div_selling(browser)
    browser.div(id: 'selling-container')
  end
  def self.divs_media_count(browser)
    self.div_selling(browser).divs(class: 'media').count
  end
  def self.nav_with_index(browser, idx)
    self.div_selling(browser).nav(class: 'pagination_more', index: idx)
  end

  # TODO : うまく動作していない可能性あり
  # def self.has_page_load_completed(browser)
  #   browser.execute_script("return document.readyState;") == "complete"
  # end
  # def self.wait_until_page_load_completed(browser)
  #   browser.wait_until(timeout: 3600) do
  #     self.has_page_load_completed(browser) # ページの読み込みが完了したら真が返るので次へ進むことができます
  #   end
  # end
  def self.wait_for_continuity(browser, opened_count)
    continuity = nil
    browser.wait_until(timeout: 3600) do
      continuity ||= :finish if self.nav_with_index(browser, opened_count).spans.count == 0
      continuity ||= :continue if self.div_selling(browser).navs.count == opened_count + 1
      continuity
    end
    continuity
  end

  def self.wait_until_overwrite(browser, best)
    browser.wait_until(timeout: 3600) do
      divs_count = self.divs_media_count(browser)
      best.overwrite_if_over(divs_count)
    end
  end

  # 「続きを見る」全展開
  def self.next_button_all_open(browser)
    media_count = Best.new(0)
    self.wait_until_overwrite(browser, media_count) # 0商品以上が表示されれば次へ進むことができるようにして処理速度問題に対処
    return nil if self.div_selling(browser).navs.count == 0
    opened_count = 0
    loop do
      self.nav_with_index(browser, opened_count).span.a.click
      self.wait_until_overwrite(browser, media_count) # 商品表示数が増加したら次へ進むことができるようにした
      opened_count += 1
      continuity = self.wait_for_continuity(browser, opened_count)
      case continuity
      when :finish
        break
      when :continue
      end
    end
  end

  def self.already_relisted?(browser, item)
    self.goto_sell(browser)
    first_item_title = browser.div(id: 'selling-container').divs(class: 'media').first.element(class: 'media-heading').text

    is_already = item['name'] == first_item_title # 一致するならエラーながらに再出品自体はうまくいっているのでリトライしない
    self.goto_new(browser)

    is_already
  end
  
end
