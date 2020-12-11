# coding: utf-8
require 'watir'
require 'open-uri'
require_relative 'rakuma_browser'

class ItemScraper
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
  def self.scrape(browser, props_url:)
    RakumaBrowser.goto_url_by_new_tab(browser, props_url)
    browser.html =~ /data-react-props="(.+?)"/
    plane = $1
    plane.gsub!('&quot;', '"')
    $main.wait_a_minute('prop')
    RakumaBrowser.close_last_tab(browser)
    self.to_hash(plane)['item']
  end
  def self.crops(browser, imgs_url:)
    RakumaBrowser.goto_url_by_new_tab(browser, imgs_url)
    img_urls = []
    count = browser.imgs(class: 'sp-image').count
    for idx in 0...count do
      img_urls << browser.img(class: 'sp-image', index: idx).src
    end
    save_dir = 'saved_img/'
    FileUtils.mkdir_p(save_dir) unless File.exists?(save_dir)
    files = img_urls.map do |url|
      self.save_with(dir: save_dir, file: url[/(\d+.\w+.)\?/, 1], url: url)
    end.map.with_index(1) do |file_name, index|
      ['img' + index.to_s, file_name]
    end.to_h
    1.upto(4) { |n| files['img' + n.to_s] ||= nil }
    $main.wait_a_minute('imgs')
    RakumaBrowser.close_last_tab(browser)
    files.to_h
  end
  def self.download(browser, items = [])
    RakumaBrowser.goto_sell(browser)
#    puts 'リストを最後まで展開したらOKしてください。'
#    RakumaBrowser.wait_dialog(browser)
    page_item_count = browser.divs(class: 'media').count
    for idx in 0..(page_item_count - 1)
      browser.div(class: 'media', index: idx).scroll.to
      edit_page_url = browser.div(class: 'media', index: idx).a(class: ['btn', 'btn-default'], index: 0).href
      imgs_page_url = browser.div(class: 'media', index: idx).div(class: 'row').a.href
      props = self.scrape(browser, props_url: edit_page_url)
      crops = self.crops(browser, imgs_url: imgs_page_url)
      updtd = { 'site_updated' => true }
      item = props.merge(crops).merge(updtd)
      items << item
    end
    items
  end
end
