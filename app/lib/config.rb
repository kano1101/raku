#!/usr/bin/env ruby
# coding: utf-8

require 'tk'
require_relative 'yaml_util'

class Config
  
  def make_entry(parent, field)
    frame = TkFrame.new(parent)
    TkLabel.new(frame, font: { size: 28 }, text: field[:text]).pack(side: 'left', anchor: 'w')
    TkEntry.new(frame, font: { size: 28 }, textvariable: @times.ref(field[:type])).pack(side: 'left', anchor: 'w').insert(0, field[:time])
    frame.pack(side: 'top', anchor: 'c')
  end
  
  def initialize
    @times = TkVariable.new_hash
    
    base = TkToplevel.new(nil, title: 'Settings')
    base.grab_set # Base Windowの操作を禁止する

    delays = YamlUtil.new.read
    fields = [
      { type: :conmin, text: '入力遅延最小値(秒)', time: delays['conmin'] },
      { type: :conmax, text: '入力遅延最大値(秒)', time: delays['conmax'] },
      { type: :submin, text: '投稿遅延最小値(秒)', time: delays['submin'] },
      { type: :submax, text: '投稿遅延最大値(秒)', time: delays['submax'] },
    ]
    fields.each do |field|
      make_entry(base, field)
    end
 
    TkButton.new(base, text: '設　定', font: { size: 28 }, command: proc { YamlUtil.new.write(@times); base.destroy }).pack(side: 'top', anchor: 'c')
    TkButton.new(base, text: '閉じる', font: { size: 28 }, command: proc { base.destroy }).pack(side: 'top', anchor: 'c')
  end
end
