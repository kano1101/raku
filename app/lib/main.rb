require_relative 'flow'

class Main
  def self.main
  print 'Do you want to download from rakuma? (\'y\' or other) : '
  do_or_not_download = gets.chomp
  Flow.download_and_generate_csv if do_or_not_download == 'y'
  Flow.restore_csv_and_relist
  end
end

if __FILE__ == $0
  Main.main
end
