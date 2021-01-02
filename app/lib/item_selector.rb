# coding: utf-8
require 'tk'
require 'tkextlib/tkimg/jpeg'
require 'tkextlib/bwidget'

class Row
  KEYS = ['id', 'name'].freeze
  IMG_KEYS = ['img1', 'img2', 'img3', 'img4'].freeze
  ALL_KEYS = KEYS + IMG_KEYS

  ORIGINAL_IMAGE_WIDTH = 640
  ORIGINAL_IMAGE_HEIGHT = 640
  COLUMN_WIDTH_IMAGE = 200
  COLUMN_WIDTHS = [100, 100, COLUMN_WIDTH_IMAGE, COLUMN_WIDTH_IMAGE, COLUMN_WIDTH_IMAGE, COLUMN_WIDTH_IMAGE].freeze
  POS_XS = COLUMN_WIDTHS.count.times.map.with_index { |idx| COLUMN_WIDTHS.dup.shift(idx).sum(0) }.freeze
  FRAME_WIDTH = COLUMN_WIDTHS.sum
  FRAME_HEIGHT = 100
  
  COLUMN_LABEL_HEIGHT = 20

  class << self
    def pack(receiver)
      receiver.pack(side: 'left', fill: 'both')
      receiver.borderwidth = 3
      receiver.relief = 'groove'
      receiver.background = :gray75
      receiver
    end
    def add_label(parent, element)
      pack(TkLabel.new(parent, text: element))
    end
    def add_image(parent, path)
      c = TkCanvas.new(parent, width: ORIGINAL_IMAGE_WIDTH, height: ORIGINAL_IMAGE_HEIGHT).pack(fill: :both, expand: true)
      TkcImage.new(c, 0, 0, image: TkPhotoImage.new(file: path))
      c.configure(width: COLUMN_WIDTH_IMAGE)
      c.configure(height: FRAME_HEIGHT)
      pack(c)
    end
    
    def place(receiver, column_idx)
      receiver.place(x: POS_XS[column_idx], y: 0,
                     width: COLUMN_WIDTHS[column_idx])#, height: height)
    end

    def make_frame(parent, is_column_label: false)
      height = is_column_label ? COLUMN_LABEL_HEIGHT : FRAME_HEIGHT
      frame = TkFrame.new(parent, width: FRAME_WIDTH, height: height) # TODO
      frame.pack(side: 'top', fill: 'both')
    end

    def make_row(parent, item)
      frame = make_frame(parent)
      KEYS.each do |key|
        element = add_label(frame, item[key])
        place(element, ALL_KEYS.index(key))
      end
      IMG_KEYS.each do |key|
        element =
          case item[key]
          when nil
            add_label(frame, '画像なし')
          else
            add_image(frame, item[key])
          end
        place(element, ALL_KEYS.index(key))
      end
    end
    
    def make_column_label(parent)
      frame = make_frame(parent, is_column_label: true)
      ALL_KEYS.each_with_index do |label_str, idx|
        label = add_label(frame, text: label_str)
        place(label, idx)
      end
    end
  end
end

class ItemSelector
  def initialize(items)
    root = TkRoot.new
    root.geometry = "1600x900+240+180"
    root.configure(bg: :gray90)
    
    window = Tk::BWidget::ScrolledWindow.new(root).pack(fill: :both)
    frame = Tk::BWidget::ScrollableFrame.new(window, constrainedwidth: true)
    window.set_widget(frame)
    row_frame = frame.get_frame
    
    pack_matrix(row_frame, items)
    pack_decide_button(root)
  end
  def pack_matrix(parent, items)
    Row.make_column_label(parent)
    items.each do |item|
      Row.make_row(parent, item)
    end
  end
  def pack_decide_button(parent)
    button = TkButton.new(parent, text: '決定', font: { size: 28 }).pack
    button.bind('ButtonRelease-1', -> { exit })
  end
end
