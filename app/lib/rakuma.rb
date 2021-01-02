#!/usr/bin/env ruby
# coding: utf-8

require 'tk'
require_relative 'config'
require_relative 'item_selector'
require_relative 'csv_writer'
require_relative 'main'

$main = Main.new

root = TkRoot.new

SOURCE_DIR = 'app/lib/'
button_info = [
  { type: :config, text: '1.出品間隔設定', script: proc { Config.new }}, # Done
  { type: :scrape, text: '2.商品情報取得', script: proc { Main.scrape }}, # Done
  { type: :select, text: '3.対象商品選択', script: proc { ItemSelector.new(CsvWriter.restore_csv) }},
  { type: :relist, text: '4.再出品　実行', script: proc { Main.relist }},
  { type: :relist, text: '閉じる'        , script: proc { exit }},
]

buttons = button_info.map do |info|
  [ info[:type], TkButton.new(root) { text info[:text]; font({ size: 28 }); command info[:script]; pack } ]
end.to_h

Tk.mainloop
