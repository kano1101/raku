# coding: utf-8
class Best
  attr_reader :value
  def initialize(value)
    @value = value
  end

  # 記録が上書きされたら真、却下されたら偽が返る（同じでは偽）
  def overwrite_if_over(value)
    if @value < value
      @value = value
    else
      nil
    end
  end
end
