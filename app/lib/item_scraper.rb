# coding: utf-8
require 'watir'
require 'open-uri'
require_relative 'rakuma_browser'

class ItemScraper
  
  SAVE_DIR = 'saved_img/'
  
  def self.to_hash(str)
    JSON.parse(str)
  end
  def self.save_with(dir:, file:, url:)
    save_path = dir + file
    URI.open(save_path, 'wb') do |path|
      URI.open(url) do |receive|
        path.write(receive.read)
      end
    end
    file
  end
  
  def self.props_scrape(browser, edit_url:)
    RakumaBrowser.goto_url_by_new_tab(browser, props_url)
    browser.html =~ /data-react-props="(.+?)"/
    plane = $1
    plane.gsub!('&quot;', '"')
    RakumaBrowser.close_last_tab(browser)
    self.to_hash(plane)['item']
  end
  
  def self.crops_scrape(browser, imgs_url:)
    RakumaBrowser.goto_url_by_new_tab(browser, imgs_url)
    img_urls = browser.imgs(class: 'sp-image').count.times.map do |idx|
      browser.img(class: 'sp-image', index: idx).src
    end
    RakumaBrowser.close_last_tab(browser)
    
    FileUtils.mkdir_p(save_dir) unless File.exists?(SAVE_DIR)
    files = img_urls.map do |url|
      self.save_with(dir: SAVE_DIR, file: url[/(\d+.\w+.)\?/, 1], url: url)
    end.map.with_index(1) do |fnm, num| # img(n)のnは1始まり
      ['img' + num.to_s, fnm]
    end.to_h
    
    # img2以降が存在しなかったらnil生成
    1.upto(4) { |num| files['img' + num.to_s] ||= nil }
    files
  end

  def self.edit_btn(target)
    target.a(class: ['btn', 'btn-default'], index: 0)
  end

  def self.target(sell_div, idx)
    sell_div.div(class: 'media', index: idx)
  end

  def self.sell_div(browser)
    browser.div(id: 'selling-container')
  end
  
  def self.item_ids_on_network(browser)
    sell_div = self.sell_div(browser)
    sell_div.divs(class: 'media').count.times.map do |idx|
      target = self.target(sell_div, idx)
      target.scroll.to
      data << self.edit_btn(target).onclick[/{'dimension1': '(.+?)'}/]
    end
    data
  end

  def self.make_item_from_network(browser, idx)
    sell_div = self.sell_div(browser)
    target = self.target(sell_div, idx)
    edit_btn = self.edit_btn(target)
    edit_page_url = edit_btn.href
    imgs_page_url = target.div(class: 'row').a.href
    props = self.props_scrape(browser, edit_url: edit_page_url)
    crops = self.crops_scrape(browser, imgs_url: imgs_page_url)
    props.merge(crops)
  end
  
  def self.download(browser, items = [])
    RakumaBrowser.goto_sell(browser)
    puts '「次へ」でリストを全て開いて最後まで展開したらEnterを押してください。'
    gets
    item_ids_on_network(browser).map.with_index do |id, idx|
      item = items.find { |item| item['id'] == id }
      item ||= make_item_from_network(browser, idx)
      puts item['name'] + 'のデータを取得しました。'
    end
  end
end
