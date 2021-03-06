module Rumx
  module Beans
    class Timer
      include Bean

      bean_attr_reader :total_count, :integer, 'Number of times the measured block has run'
      bean_attr_reader :count,       :integer, 'Number of times the measured block has run since the last reset'
      bean_attr_reader :max_time,    :float,   'The maximum time (msec) for all the runs of the timed instruction'
      bean_attr_reader :min_time,    :float,   'The minimum time (msec) for all the runs of the timed instruction'
      bean_attr_reader :last_time,   :float,   'The time (msec) for the last run of the timed instruction'
      bean_reader      :avg_time,    :float,   'The average time (msec) for all runs of the timed instruction'
      bean_writer      :reset,       :boolean, 'Reset the times and counts to zero (Note that total_count and last_time are not reset)'

      def initialize(opts={})
        # Force initialization of Bean#bean_monitor to avoid race condition (See bean.rb)
        bean_monitor
        @total_count = 0
        @last_time   = 0.0
        self.reset   = true
      end

      def reset=(val)
        if val
          @count    = 0
          @min_time = nil
          @max_time = 0.0
          @sum_time = 0.0
        end
      end

      def measure
        start_time = Time.now
        begin
          yield
        ensure
          current_time = (Time.now.to_f - start_time.to_f) * 1000.0
          bean_synchronize do
            @last_time    = current_time
            @count       += 1
            @total_count += 1
            @sum_time    += current_time
            @min_time     = current_time if !@min_time || current_time < @min_time
            @max_time     = current_time if current_time > @max_time
          end
        end
        return current_time
      end

      def min_time
        @min_time || 0.0
      end

      def avg_time
        # Do the best we can w/o mutexing
        count, time = @count, @sum_time
        return 0.0 if count == 0
        time / count
      end

      def to_s
        "total_count=#{@total_count} count=#{@count} min=#{('%.1f' % min_time)}ms max=#{('%.1f' % max_time)}ms avg=#{('%.1f' % avg_time)}ms"
      end
    end
  end
end
