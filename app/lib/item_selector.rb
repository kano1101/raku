# coding: utf-8
require 'tk'
require 'tkextlib/tkimg/jpeg'
require 'tkextlib/bwidget'
require_relative 'csv_writer'

class Row
  KEYS = ['scheduled', 'name', 'detail'].freeze
  IMG_KEYS = ['img1', 'img2', 'img3', 'img4'].freeze
  OTHER_KEYS = ['origin_price', 'created_at', 'updated_at', 'category_name', 'size_name'].freeze
  ALL_KEYS = KEYS + IMG_KEYS + OTHER_KEYS

  SMALL_FONT_SIZE = 12

  MINI_DIR = 'saved_img_mini/'

  ORIGINAL_IMAGE_WIDTH = 640
  ORIGINAL_IMAGE_HEIGHT = 640
  MINI_IMAGE_WIDTH = ORIGINAL_IMAGE_WIDTH * 0.2
  MINI_IMAGE_HEIGHT = ORIGINAL_IMAGE_HEIGHT * 0.2
  
  COLUMN_WIDTHS = [64, 180, 180, *Array.new(IMG_KEYS.count, MINI_IMAGE_WIDTH), *Array.new(OTHER_KEYS.count, 112)].freeze
  POS_XS = COLUMN_WIDTHS.count.times.map.with_index { |idx| COLUMN_WIDTHS.dup.shift(idx).sum(0) }.freeze
  FRAME_WIDTH = COLUMN_WIDTHS.sum
  FRAME_HEIGHT = MINI_IMAGE_WIDTH
  
  COLUMN_LABEL_HEIGHT = 28

  class << self
    def pack(receiver)
      receiver.borderwidth = 1
      receiver.relief = :groove
      receiver.background = :gray75
      receiver.pack(side: :left, fill: :both, anchor: :w)
    end
    def place(receiver, column_idx, is_column_label: false)
      height = is_column_label ? COLUMN_LABEL_HEIGHT : FRAME_HEIGHT
      receiver.place(x: POS_XS[column_idx], y: 0, width: COLUMN_WIDTHS[column_idx], height: height)
    end
    def make_frame(parent, is_column_label: false)
      height = is_column_label ? COLUMN_LABEL_HEIGHT : FRAME_HEIGHT
      frame = TkFrame.new(parent, width: FRAME_WIDTH, height: height) # TODO
      frame.pack(side: :top, fill: :both)
    end
    
    def add_label(parent, element)
      l = TkLabel.new(parent, text: element, anchor: :c)
      l.font({ size: SMALL_FONT_SIZE })
      pack(l)
    end
    def add_image(parent, path)
      c = TkCanvas.new(parent, width: MINI_IMAGE_WIDTH, height: MINI_IMAGE_HEIGHT)
      TkcImage.new(c, 0, 0, anchor: :nw, image: TkPhotoImage.new(file: path))
      c.pack
    end
    
    def make_row_label(keys, frame, item)
      keys.each do |key|
        element = add_label(frame, item[key])
        length = COLUMN_WIDTHS[ALL_KEYS.index(key)]
        element.configure(wraplength: length)
        place(element, ALL_KEYS.index(key))
      end
    end
    def make_row_image(keys, frame, item)
      keys.each do |key|
        element =
          case item[key]
          when nil
            add_label(frame, '画像なし')
          else
            add_image(frame, MINI_DIR + item[key])
          end
        place(element, ALL_KEYS.index(key))
      end
    end
    
    def make_row(parent, item)
      frame = make_frame(parent)
      make_row_label(KEYS, frame, item)
      make_row_image(IMG_KEYS, frame, item)
      make_row_label(OTHER_KEYS, frame, item)
    end
    def make_column_label(parent)
      frame = make_frame(parent, is_column_label: true)
      ALL_KEYS.each_with_index do |label_str, idx|
        element = add_label(frame, label_str)
        place(element, idx, is_column_label: true)
      end
    end
  end
end

class ItemSelector
  MATRIX_FRAME_WIDTH = Row::FRAME_WIDTH.to_i
  WINDOW_WIDTH = MATRIX_FRAME_WIDTH + 18
  
  def initialize(items)
    base = TkToplevel.new(nil, title: '再出品対象選択ウィンドウ')
    base.grab_set
    base.geometry = "#{WINDOW_WIDTH}x900+240+180"
    base.configure(bg: :gray90)

    matrix_frame = TkFrame.new(base, width: MATRIX_FRAME_WIDTH).pack(side: :top, fill: :both)
    
    window = Tk::BWidget::ScrolledWindow.new(matrix_frame).pack(fill: :both)
    frame = Tk::BWidget::ScrollableFrame.new(window, constrainedwidth: true, height: 864)
    window.set_widget(frame)
    row_frame = frame.get_frame
    
    pack_matrix(row_frame, items)

    button_frame = TkFrame.new(base).pack(side: :top)
    TkButton.new(button_frame, text: '決定', font: { size: 28 }, command: proc { CsvWriter.generate_csv(items); base.destroy }).pack(side: :left, anchor: :c)
    TkButton.new(button_frame, text: '閉じる', font: { size: 28 }, command: proc { base.destroy }).pack(side: :left, anchor: :c)
  end
  def pack_matrix(parent, items)
    Row.make_column_label(parent)
    items.each do |item|
      Row.make_row(parent, item)
    end
  end
end
