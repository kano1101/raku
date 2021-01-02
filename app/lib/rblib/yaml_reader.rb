require 'yaml'

module YamlReader
  def write(data)
    file = File.open(self.path, 'w')
    YAML.dump(data.to_hash, file)
    file.close
  end
  def read
    open(self.path, 'r') { |f| YAML.load(f) }
  end
end
