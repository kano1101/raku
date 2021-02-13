module TimesRetry

  refine Integer do
    def times_retry(message: true)
      n = 1
      begin
        yield(n)
      rescue => e
        if n <= self
          puts "#{e.class}: retry #{n}" if message
          n += 1
          retry
        end
        puts "#{e.class}: abort" if message
        puts e.backtrace if message
        raise e
      end
    end
  end

end
