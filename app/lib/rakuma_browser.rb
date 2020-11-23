# coding: utf-8
require 'watir'

class RakumaBrowser
  def self.wake_up
    switches = %W[--user-data-dir=./UserData/]
    Watir::Browser.new :chrome, switches: switches
  end
  
  def self.goto_url(browser, url, wait_sec: 2.5)
    browser.goto(url)
    browser.wait
    wait_a_minute(browser, wait_sec: wait_sec)
  end
  def self.goto_login(browser)
    login_url = 'https://fril.jp/users/sign_in'
    goto_url(browser, login_url)
  end
  def self.goto_sell(browser)
    sell_url = "https://fril.jp/sell"
    goto_url(browser, sell_url)
  end
  def self.goto_new(browser)
    new_url = "https://fril.jp/item/new"
    goto_url(browser, new_url)
  end
  
  def self.wait_a_minute(browser, wait_sec:)
    random = Random.new()
    wait_sec = random.rand(wait_sec * 1.0 .. wait_sec * 3.0)
    sleep(wait_sec)
  end

  def self.auto_close(browser)
    browser.close
  end
  def self.wait_close(browser)
    browser.wait_while(timeout: 600) do |b|
      b.exists?
    end
    browser.close
  end
  
  def self.is_goto_sell_success(browser)
    /<title>出品した商品｜ラクマ<\/title>/ =~ browser.html
  end

  def self.start_up
    browser = wake_up
    goto_sell(browser)
    unless self.is_goto_sell_success(browser)
      # 一度目ならログインが必要であり、browserは更新される
      auto_close(browser) # 画面遷移のため自動的に閉じる
      browser = wake_up
      goto_login(browser)
      wait_close(browser) # 手動でブラウザが閉じられるのを待つ
      browser = wake_up
      goto_sell(browser)
      raise "ログインに失敗しました。" unless self.is_goto_sell_success(browser)
    end
    browser
  end

  def self.exit(browser)
    browser.close
  end

  def self.goto_url_by_new_tab(browser, url)
    browser.execute_script("window.open()")
    browser.windows.last.use
    self.goto_url(browser, url)
  end
  def self.close_last_tab(browser)
    browser.windows.last.close
  end
#  def self.wait_dialog(browser)
    # dialog = Watir::Dialog new
    # wait_while(browser) { || dialog.present? }
#  end
end
