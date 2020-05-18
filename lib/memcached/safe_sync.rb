require 'monitor'

# The intend of class "SafeSync" is to provide a multithread-safe cache acces, ensuring that:

# => Readers access cache only when there are no writers
# => Writers access cache only when there are no readers or writers
# => Only one thread manipulate the state variables at a time

# In terms of reader-writers fairness:

# => Once a reader is waiting, readers will get in next
# => If a writer is waiting, one writer will get in next

module Memcached
  class SafeSync
    include MonitorMixin
    def initialize
      super
      @writing = false
      @active_readers_count = 0
      @blocked_readers_count = 0
      @blocked_writers_count = 0

      @canRead = new_cond
      @canWrite = new_cond
    end
    
    def start_reading
      synchronize{
        if @writing || (@blocked_writers_count > 0)
          @blocked_readers_count += 1
          @canRead.wait
          @blocked_readers_count -= 1
        end

        @active_readers_count += 1
        @canRead.signal
      }
    end

    def finish_reading
      synchronize{
        @active_readers_count -= 1
        if (@active_readers_count == 0)
          @canWrite.signal
        end
      }
    end

    def start_writing
      synchronize{
        if @writing || (@active_readers_count > 0)
          @blocked_writers_count += 1
          @canWrite.wait
          @blocked_writers_count -= 1
        end
        @writing = true
      }
    end

    def finish_writing
      synchronize{
        @writing = false
        if (@blocked_readers_count > 0)
          @canRead.signal
        else
          @canWrite.signal
        end
      }
    end
  end
end