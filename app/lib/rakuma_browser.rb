# coding: utf-8
require 'yaml'
require 'watir'
require_relative 'main'
require_relative 'rblib/best'

class RakumaBrowser
  
  USER_DATA_DIR = %W[--user-data-dir=./UserData/]
  def self.wake_up
    browser = Watir::Browser.new :chrome, switches: USER_DATA_DIR
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
    self.next_button_span(browser).a(index: 0)
  end
  def self.has_page_load_completed(browser)
    browser.execute_script("return document.readyState;") == "complete"
  end
  def self.wait_until_page_load_completed(browser)
    browser.wait_until(timeout: 3600) do
      print 'ページが完全に読み込まれたらtrue : '
      p self.has_page_load_completed(browser) # ページの読み込みが完了したら真が返るので次へ進むことができます
    end
  end
  def self.wait_for_continuity(browser, opened_count)
    continuity = nil
    browser.wait_until(timeout: 3600) do
      continuity ||= :finish if browser.div(id: 'selling-container').nav(class: 'pagination_more', index: opened_count).spans.count == 0
      continuity ||= :continue if browser.div(id: 'selling-container').navs.count == opened_count + 1
      continuity
    end
    continuity
  end
  
  def self.next_button_all_open(browser)
    self.wait_until_page_load_completed(browser)
    return nil if browser.div(id: 'selling-container').navs.count == 0
    media_count = Best.new(browser.div(id: 'selling-container').divs(class: 'media').count)
    opened_count = 0
    loop do
      browser.div(id: 'selling-container').nav(class: 'pagination_more', index: opened_count).span.a.click
      browser.wait_until(timeout: 3600) do # 商品表示数が増加したら次へ進むことができるようにした
        media_count.overwrite_if_over(browser.div(id: 'selling-container').divs(class: 'media').count)
      end
      
      opened_count += 1
      continuity = self.wait_for_continuity(browser, opened_count)
      case continuity
      when :finish
        break
      when :continue
      end
    end
    puts "リストは#{opened_count}回展開されました。"
  end

end
