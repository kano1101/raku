require 'yaml'
require_relative 'rblib/yaml_reader'

class YamlUtil
  YML_DIR = ''
  YML_FILE = 'settings.yml'
  YML_PATH = YML_DIR + YML_FILE

  include YamlReader

  def write(data)
    super
  end
  def read
    super
  end
  def path
    YML_PATH
  end
end
