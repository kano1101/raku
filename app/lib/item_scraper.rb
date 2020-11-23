# coding: utf-8
require 'watir'
require_relative 'rakuma_browser'

class ItemScraper
  def self.to_hash(str)
    JSON.parse(str)
  end
  def self.scrape(browser, url)
    RakumaBrowser.goto_url_by_new_tab(browser, url)
    browser.html =~ /data-react-props="(.+?)"/
    plane = $1
    plane.gsub!('&quot;', '"')
    RakumaBrowser.close_last_tab(browser)
    self.to_hash plane
  end
  def self.download(browser, items = [])
    RakumaBrowser.goto_sell(browser)
    puts 'リストを最後まで展開したらOKしてください。'
#    RakumaBrowser.wait_dialog(browser)
    page_item_count = browser.divs(class: "media").count
    for idx in 0..(page_item_count - 1)
      browser.div(class: "media", index: idx).scroll.to
      url = browser.div(class: "media", index: idx).a(class: ["btn", "btn-default"], index: 0).href
      item = ItemScraper.scrape(browser, url)
      items << item["item"]
    end
    items
  end
end

