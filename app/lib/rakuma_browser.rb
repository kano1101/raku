# coding: utf-8
require 'yaml'
require 'watir'
require_relative 'main'

class RakumaBrowser
  def self.wake_up
    switches = %W[--user-data-dir=./UserData/]
    browser = Watir::Browser.new :chrome, switches: switches#, headless: true
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
    browser.div(id: 'selling-container').wait_until_present
  end
  def self.goto_new(browser)
    new_url = 'https://fril.jp/item/new'
    goto_url(browser, new_url)
  end

  def self.auto_close(browser)
    browser.close
  end
  def self.wait_close(browser)
    browser.wait_while(timeout: 600, &:exists?)
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
end
