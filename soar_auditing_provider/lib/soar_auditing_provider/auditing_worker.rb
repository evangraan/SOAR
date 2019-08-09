require 'soar_thread_worker/thread_worker'
require 'singleton'

module SoarAuditingProvider
  class AuditingWorker < SoarThreadWorker::ThreadWorker
    include Singleton

    def initialize
      @queue = Queue.new
      @queue_mutex = Mutex.new
      initialize_metrics
      super
    end

    def configure(queue_worker_configuration: ,auditor_audit_method: )
      validate_configuration(queue_worker_configuration)
      @maximum_queue_size = queue_worker_configuration['queue_size'].to_i
      @initial_back_off_in_seconds = queue_worker_configuration['initial_back_off_in_seconds'].to_i
      @back_off_multiplier = queue_worker_configuration['back_off_multiplier'].to_i
      @maximum_back_off_attempts = queue_worker_configuration['back_off_attempts'].to_i
      @auditor_audit_method = auditor_audit_method
    end

    def enqueue(level, data)
      @queue_mutex.synchronize {
        raise AuditingOverflowError if @queue.size >= @maximum_queue_size
        @queue.push({:level => level, :data => data})
        start
      }
    end

    def execute
      audit_event = nil
      @queue_mutex.synchronize {
        @thread.exit if @queue.empty?
        audit_event = @queue.pop
      }
      @dequeued_audits += 1
      failed_before = false
      begin
        if @stopping
          @queue_mutex.synchronize {
            @queue.push(audit_event) if audit_event #push the event back into the queue so that fallback flush mechanism can deal with this audit event
            @thread.exit
          }
        end
        exponential_back_off(start_at_last_attempt: failed_before) {
          time_before_audit = Time.now
          @auditor_audit_method.call(audit_event[:level],audit_event[:data])
          @latest_successful_audit_timespan = (Time.now - time_before_audit).round(3)
          @latest_successful_audit_timestamp = Time.now.utc.iso8601(3)
          @successful_audits += 1
        }
      rescue Exception => e
        print_exception_with_message_to_stderr(nil,e)
        failed_before = true
        retry
      end

      @queue_mutex.synchronize {
        return false if not @queue.empty? #indicates to thread worker that we are not done executing since the queue is not empty
        @thread.exit
      }
    end

    def flush(timeout:)
      start #start the worker thread just in case there are items enqueued
      sleep(0.1)
      stop(immediate: false)
      wait_for_worker_to_clear_queue(timeout)
      stop(immediate: true)
      fallback_flush_to_stderr (timeout) if not @queue.empty?
    end

    def status_detail
      {
        'queue_size'                           => @queue.size,
        'dequeued_audits'                      => @dequeued_audits,
        'successful_audits'                    => @successful_audits,
        'failed_audit_attempts'                => @failed_audit_attempts,
        'latest_successful_audit_timespan'     => @latest_successful_audit_timespan,
        'latest_successful_audit_timestamp'    => @latest_successful_audit_timestamp,
        'latest_failed_audit_timestamp'        => @latest_failed_audit_timestamp,
        'latest_failed_audit_error_message'    => @latest_failed_audit_error_message
      }
    end

    private

    def wait_for_worker_to_clear_queue(timeout)
      start_time = Time.now
      until ((not @thread.alive?) or ((Time.now - start_time) >= timeout)) do
        sleep(0.1)
      end
    end

    def fallback_flush_to_stderr(timeout)
      $stderr.puts 'Unable to flush audit entries to auditor, stopping worker and flushing to stderr'
      ensure_worker_is_stopped
      start_time = Time.now
      until ((@queue.size == 0) or ((Time.now - start_time) >= timeout)) do
        audit_event = @queue.pop
        $stderr.puts audit_event[:data].to_s
      end
    rescue Exception => e
      print_exception_with_message_to_stderr('Failure during fallback attempt to flush audit entries to stderr',e)
      raise
    end

    def print_exception_with_message_to_stderr(notification,exception)
      message = "#{exception.class}: #{exception.message}"
      message = message + ":\n\t" + exception.backtrace.join("\n\t")
      $stderr.puts "#{notification}: #{message}"
    end

    def ensure_worker_is_stopped
      stop(immediate: false)
      sleep_while_still_running(2)
      stop(immediate: true)
    end

    def validate_configuration(queue_worker_configuration)
      raise ArgumentError.new("Invalid queue size (#{queue_worker_configuration['queue_size'].to_i})") if queue_worker_configuration['queue_size'].to_i < 1
      raise ArgumentError.new("Invalid number of back off attempts (#{queue_worker_configuration['back_off_attempts'].to_i})") if queue_worker_configuration['back_off_attempts'].to_i < 1
    end

    def exponential_back_off(start_at_last_attempt: false)
      attempt = 1
      if start_at_last_attempt
        attempt = @maximum_back_off_attempts
        sleep_unless_stopping(calculate_back_off_delay(@maximum_back_off_attempts))
      end
      begin
        yield
      rescue StandardError => exception
        # Any exception derived from StandardError is assumed to be a failure and
        # attempted again until it completes without an exception or an exception
        # not derived from StandardError
        @latest_failed_audit_error_message = "#{exception.class}: #{exception.message}"
        @latest_failed_audit_timestamp = Time.now.utc.iso8601(3)
        @failed_audit_attempts += 1
        if ((attempt <= @maximum_back_off_attempts) and (not @stopping)) then
          sleep_unless_stopping(calculate_back_off_delay(attempt))
          attempt = attempt + 1
          retry
        else
          raise
        end
      end
    end

    def calculate_back_off_delay(attempt)
      @initial_back_off_in_seconds * (@back_off_multiplier ** (attempt-1))
    end

    def sleep_unless_stopping(desired_delay)
      start_time = Time.now
      until (@stopping or ((Time.now - start_time) >= desired_delay)) do
        sleep(0.1)
      end
    end

    def sleep_while_still_running(desired_delay)
      start_time = Time.now
      until ((false == running?) or ((Time.now - start_time) >= desired_delay)) do
        sleep(0.1)
      end
    end

    def initialize_metrics
      @failed_audit_attempts = 0
      @latest_failed_audit_timestamp = 0
      @successful_audits = 0
      @latest_successful_audit_timestamp = 0
      @dequeued_audits = 0
      @latest_successful_audit_timespan = 0
      @latest_failed_audit_error_message = "None"
    end
  end
end
