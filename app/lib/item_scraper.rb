# coding: utf-8
require 'watir'
require 'open-uri'
require 'tk'
require 'RMagick'
require_relative 'rakuma_browser'

class ItemScraper
  
  SAVE_DIR = 'saved_img/'
  MINI_DIR = 'saved_img_mini/'
  
  def self.to_hash(str)
    JSON.parse(str)
  end
  def self.save_with(file:, url:)
    save_path = SAVE_DIR + file
    URI.open(save_path, 'wb') do |path|
      URI.open(url) do |receive|
        path.write(receive.read)
      end
    end
  end
  def self.make_mini(file:, rate:)
    save_path = MINI_DIR + file
    Magick::Image.read(SAVE_DIR + file).first.resize(rate).write(save_path)
  end
  
  def self.props_scrape(browser, edit_url:)
    RakumaBrowser.goto_url(browser, edit_url)
    browser.html =~ /data-react-props="(.+?)"/
    plane = $1
    plane.gsub!('&quot;', '"')
    self.to_hash(plane)['item']
  end
  
  def self.crops_scrape(browser, imgs_url:)
    RakumaBrowser.goto_url(browser, imgs_url)
    img_urls = browser.imgs(class: 'sp-image').count.times.map do |idx|
      browser.img(class: 'sp-image', index: idx).src
    end
    
    FileUtils.mkdir_p(save_dir) unless File.exists?(SAVE_DIR)
    FileUtils.mkdir_p(save_dir) unless File.exists?(MINI_DIR)
    files = img_urls.map do |url|
      file_name = url[/(\d+.\w+.)\?/, 1]
      self.save_with(file: file_name, url: url)
      self.make_mini(file: file_name, rate: 0.2)
      file_name
    end.map.with_index(1) do |fnm, num| # img(n)のnは1始まり
      ['img' + num.to_s, fnm]
    end.to_h
    
    # img2以降が存在しなかったらnil生成
    1.upto(4) { |num| files['img' + num.to_s] ||= nil }
    files
  end

  def self.make_scheduled
    { 'scheduled' => true }
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
      self.edit_btn(target).onclick[/{'dimension1': '(.+?)'}/, 1].to_i
    end
  end
  def self.get_urls_from_network(browser)
    item_ids_on_network(browser).map.with_index do |id, idx|
      sell_div = self.sell_div(browser)
      target = self.target(sell_div, idx)
      edit_btn = self.edit_btn(target)
      edit_url = edit_btn.href
      imgs_url = target.div(class: 'row').a.href
      { 'edit' => edit_url, 'imgs' => imgs_url }
    end
  end
  
  def self.make_item_from_network(browser, url_hash)
    props = self.props_scrape(browser, edit_url: url_hash['edit'])
    crops = self.crops_scrape(browser, imgs_url: url_hash['imgs'])
    sched = self.make_scheduled
    props.merge(crops).merge(sched)
  end
  
  def self.download(browser)
    RakumaBrowser.goto_sell(browser)
    # ページの評価が早すぎて古いページを評価してしまう可能性がある問題をつぶす
    RakumaBrowser.wait_sell_page_starting(browser)
    # 古いページを抜けたらページが完全に読み込まれるまで一旦待機し「続きを見る」全展開
    RakumaBrowser.next_button_all_open(browser)
    
    urls = get_urls_from_network(browser)
    puts "全#{urls.count}商品見つかりました。"
    items = urls.map.with_index do |url_hash, idx|
      puts "#{idx + 1}商品目を読み込んでいます。"
      make_item_from_network(browser, url_hash)
    end
    keys = 1.upto(4).map { |n| 'img' + n.to_s }
    ok_file_names = items.map do |item|
      keys.map do |key|
        item[key]
      end
    end.flatten.compact
    select_ng_files(ok_files: ok_file_names, dir: SAVE_DIR).each { |path| File.delete(path) }
    select_ng_files(ok_files: ok_file_names, dir: MINI_DIR).each { |path| File.delete(path) }
    items
  end

  def self.select_ng_files(ok_files:, dir:)
    Dir.glob(dir + '*').map.select do |path|
      !ok_files.include?(File.basename(path))
    end
  end
end
