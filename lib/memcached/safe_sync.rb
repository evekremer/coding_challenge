# frozen_string_literal: true

require 'monitor'

module Memcached
  # The intend of class "SafeSync" is to provide a multithread-safe cache acces:
  # => Readers access cache only when there are no writers
  # => Writers access cache only when there are no readers or writers
  # => Only one thread manipulate the state variables at a time

  # In terms of reader-writers fairness:
  # => Once a reader is waiting, readers will get in next
  # => If a writer is waiting, one writer will get in next
  class SafeSync
    include MonitorMixin
    def initialize
      super
      @writing = false
      @active_readers_count = 0
      @blocked_readers_count = 0
      @blocked_writers_count = 0

      @can_read = new_cond
      @can_write = new_cond
    end

    def start_reading
      synchronize do
        if @writing || @blocked_writers_count.positive?
          @blocked_readers_count += 1
          @can_read.wait
          @blocked_readers_count -= 1
        end

        @active_readers_count += 1
        @can_read.signal
      end
    end

    def finish_reading
      synchronize  do
        @active_readers_count -= 1
        @can_write.signal if @active_readers_count.zero?
      end
    end

    def start_writing
      synchronize do
        if @writing || @active_readers_count.positive?
          @blocked_writers_count += 1
          @can_write.wait
          @blocked_writers_count -= 1
        end
        @writing = true
      end
    end

    def finish_writing
      synchronize  do
        @writing = false
        if @blocked_readers_count.positive?
          @can_read.signal
        else
          @can_write.signal
        end
      end
    end
  end
end
