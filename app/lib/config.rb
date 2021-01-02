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

  def is_valid_times
    return false if @times[:conmin].to_f < 0
    return false if @times[:submin].to_f < 0
    return false if @times[:conmin].to_f > @times[:conmax].to_f
    return false if @times[:submin].to_f > @times[:submax].to_f
    true
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

    button_info = [
      { text: '設　定', command: proc { YamlUtil.new.write(@times) if is_valid_times; base.destroy } },
      { text: '閉じる', command: proc { base.destroy } },
    ]
    button_info.each do |info|
      TkButton.new(base) {
        text info[:text]
        command info[:command]
        font({ size: 28 })
      }.pack(side: 'top', anchor: 'c')
    end
  end
end
