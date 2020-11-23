# coding: utf-8
require 'watir'
require_relative 'rakuma_browser'

class ItemRegister
  def self.match_index(str_array, str)
    str_array.index { |e_str| e_str == str }
  end
  def self.find_scroll_locate(browser, item)
    scan_id_array = browser.html.scan(/gaConfirm\('(.+?)'\);/).map { |wrapped| wrapped[0] }
    id = item['id'].to_s
    match_index(scan_id_array, id)
  end
  
  def self.delete(browser, item)
    idx = self.find_scroll_locate(browser, item)
    idx
    # browser.a(class: ["btn", "btn-default"], index: idx).fire_event :onclick
    # browser.alert.wait_until(&:present?).ok
  end

  def self.regist(browser, item)
    # TODO : 2020.11.23 ここをつぶしたい
    binding.pry
  end
  
  def self.relist(browser, items)
    RakumaBrowser.goto_new(browser)
    items.each do |item|
      self.delete(browser, item)
      RakumaBrowser.goto_new(browser)
      self.regist(browser, item)
    end
  end
end
