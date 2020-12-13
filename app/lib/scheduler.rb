# coding: utf-8
require_relative 'main'

class Scheduler
  def self.add_schedule(items)
    now = Time.now
    result_items = []
    items.inject(now) do |start_time, item|
      schedule = {}
      required = {}
      scene_keys = ['relist', 'submit']
      scene_keys.each do |key|
        required[key] = $main.make_wait_time(key).to_i
      end
      required.inject(start_time) do |schedule_time, (key, time_required)|
        schedule[key] = schedule_time + time_required
      end
      result_items << item.merge(schedule)
      schedule[scene_keys[-1]]
    end
    result_items
  end
  def self.print_schedule(items)
    items.each do |item|
      puts '出品完了予定時刻' + ' : ' + item['submit'].strftime('%H:%M:%S') + ' : ' + '商品[' + item['name'] + ']'
    end
  end
end
