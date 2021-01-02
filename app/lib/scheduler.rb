# coding: utf-8
require_relative 'main'
require 'tk'

class ScheduleViewer
  attr_reader :items
  def initialize(items)
    @items = []
    now = Time.now
    items.inject(now) do |start_time, item|
      schedule = {}
      required = {}
      scene_keys = ['confirm', 'submit']
      scene_keys.each do |key|
        required[key] = $main.make_wait_time(key).to_i
      end
      required.inject(start_time) do |schedule_time, (key, time_required)|
        schedule[key] = schedule_time + time_required
      end
      @items << item.merge(schedule)
      schedule[scene_keys[-1]]
    end
#    result_items
  end
  # def self.print_schedule(items)
  #   items.each do |item|
  #     puts '出品完了予定時刻' + ' : ' + item['submit'].strftime('%H:%M:%S') + ' : ' + '商品[' + item['name'] + ']'
  #   end
  # end
end


class ScheduleRow
  PROPS_KEYS = ['id', 'name',
                # 'detail',
                'origin_price', 'sell_price', 'created_at', 'updated_at',
                'category_name', 'size_name', 'brand_name', 'delivery_method']
  def self.pack_row(parent, to_v)
    PROPS_KEYS.map do |key|
      TkButton.new(parent, text: to_v[key]).pack(fill: 'both', side: 'left', anchor: 'w')
    end
  end
  def self.pack_column_label(root)
    self.pack_row(root, ->(key) { key })
  end
  attr_reader :item
  def initialize(frame, item)
    @item = item
    self.class.pack_row(frame, ->(key) { item[key] })
  end
end

class ScheduleMatrix
  def pack_matrix(parent, items)
    column_label_frame = TkFrame.new(parent)
    ScheduleRow.pack_column_label(column_label_frame)
    column_label_frame.pack(side: 'top', anchor: 'c')
    items.each do |item|
      frame = TkFrame.new(parent)
      ScheduleRow.new(frame, item)
      frame.pack(side: 'top', anchor: 'c')
    end
  end
  def pack_go_button(parent, go_proc)
    button = TkButton.new(parent, text: '実行').pack
    button.bind('ButtonRelease-1', go_proc)
  end
  def initialize(items, go_proc)
    root = TkRoot.new
    pack_matrix(root, items)
    pack_go_button(root, go_proc)
  end
end

class ScheduleController
  attr_reader :viewer, :matrix
  def initialize(items, go_proc)
    @viewer = ScheduleViewer.new(items)
    @matrix = ScheduleMatrix.new(items, go_proc)
    puts 'スケジューリングを行いました。'
  end
end
