# coding: utf-8
require 'yaml'
require 'watir'
require_relative 'main'

class RakumaBrowser
  
  USER_DATA_DIR = %W[--user-data-dir=./UserData/]
  def self.wake_up
    client = Selenium::WebDriver::Remote::Http::Default.new
    client.read_timeout = 2 # seconds – default is 60
    browser = Watir::Browser.new(:chrome, switches: USER_DATA_DIR, http_client: client) #headless true
    goto_mypage(browser)
    browser
  end
  
  def self.goto_url(browser, url)
    browser.goto(url)
    begin
      browser.wait
    rescue Watir::Wait::TimeoutError
      retry
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
    self.next_button_span(browser).a
  end
  def self.had_page_load_completed(browser)
    browser.execute_script("return document.readyState;") == "complete"
  end
  def self.wait_page_load_complete(browser)
    browser.wait_until(timeout: 3600) do
      self.had_page_load_completed(browser) # ページの読み込みが完了したら真が返るので次へ進むことができます
    end
  end
  def self.wait_while_next_button_present(browser)
    browser.wait_while(timeout: 3600) do
      self.next_button_span(browser).present? # 次を開くボタンがいなくなったら偽が返るので次へ進むことができます
    end
  end
  
  def self.next_button_all_open(browser)
    # 「続きを見る」最後まで全展開
    while self.next_button_anchor(browser).exists? # 最後まで「続きを見る」を開くために存在を確認している
      self.next_button_anchor(browser).click # 「続きを見る」をクリック
      # ページ更新状態の調査ループ
      loop do
        is_loaded = had_page_load_completed(browser) # TODO : document.readyStateの仕様を確認したい
        # 次はもしfalseが出るならクリックで一度ページがcompleteでなくなることを表す（重要確認事項）
        p 'document.readyStateがcomplete(ページを読み込み終えている)であれば真です。：' + is_loaded.to_s
        break if is_loaded
      end
      # それを待たずしてここへ入らなければならないかもしれないので厄介
      self.wait_while_next_button_present(browser) # 「続きを見る」が消えるのを待ち次へ（すでに次の「続きを見る」が表示されていたらここでTimeoutを吐く）
    end
  end

end
