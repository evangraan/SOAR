require 'soar_auditing_format'
require 'soar_json_auditing_format'
require 'soar_configured_factory'
require 'soar_flow'
require 'time'
require 'securerandom'

module SoarAuditingProvider
  class AuditingProvider
    DEFAULT_NFRS = {} unless defined? DEFAULT_NFRS; DEFAULT_NFRS.freeze
    DEFAULT_FLOW_ID_GENERATOR = -> { SoarFlow::ID::generate_flow_id } unless defined?(DEFAULT_FLOW_ID_GENERATOR)
    DEFAULT_LEVEL = :info unless defined?(DEFAULT_LEVEL)
    DEFAULT_QUEUE_WORKER_CONFIG = {
      "queue_size" => 1000,
      "initial_back_off_in_seconds" => 1,
      "back_off_multiplier" => 2,
      "back_off_attempts" => 5
    } unless defined?(DEFAULT_QUEUE_WORKER_CONFIG)

    attr_accessor :service_identifier
    attr_reader   :configuration
    attr_writer   :startup_flow_id

    def initialize(configuration)
      @configuration = configuration

      @auditors = create_auditors(configuration)
      raise ArgumentError.new("Invalid auditors provided") if not @auditors.is_a?(Hash)
      raise ArgumentError.new("No auditors provided") if @auditors.nil? or @auditors.empty?

      select_auditor(configuration['default_nfrs'])
      @flow_id_generator = @configuration["flow_id_generator"] || DEFAULT_FLOW_ID_GENERATOR
      create_auditing_worker
      @buffer_overflow_count = 0
      install_at_exit_handler
      initialize_metrics
    end

    def startup_flow_id
      @startup_flow_id ||= @flow_id_generator.call
    end

    def select_auditor(nfrs)
      select(nfrs)
      set_audit_level(configured_audit_level)
    end

    def set_audit_level(level)
      @auditor.set_audit_level(level)
    rescue ArgumentError
      $stderr.puts 'Invalid auditing level'
      raise
    end

    def debug(data, flow_identifier = nil)
      audit(:debug, data, flow_identifier)
    end

    def info(data, flow_identifier = nil)
      audit(:info, data, flow_identifier)
    end

    alias_method :<<, :info

    def warn(data, flow_identifier = nil)
      audit(:warn, data, flow_identifier)
    end

    def error(data, flow_identifier = nil)
      audit(:error, data, flow_identifier)
    end

    def fatal(data, flow_identifier = nil)
      audit(:fatal, data, flow_identifier)
    end

    def detailed_status
      detail = basic_status_detail
      detail = detail.merge(verbose_status_detail) if @configuration['verbose_detail']
      detail
    end

    def flush(timeout: 1)
      if @worker
        @worker.flush(timeout: timeout)
      end
    end

    def audit_exception(exception:, level: :error, flow_id: nil, message: nil)
      exception_message = "#{exception.class}: #{exception.message}"
      exception_message = "#{message} - #{exception_message}" if message
      exception_message = exception_message + ":\n\t" + exception.backtrace.join("\n\t")
      level = :error if not is_valid_audit_level?(level)
      send(level,exception_message,flow_id)
    end

    def select(nfrs = DEFAULT)
      if nfrs.nil? or nfrs.empty?
        auditor_selected = @auditors.keys.first
      else
        auditor_selected = nil
        @auditors.each do |auditor, configuration|
          auditor_nfrs = configuration['nfrs']
          nfrs_matched = true
          nfrs.each do |nfr, value|
            nfrs_matched = false if not auditor_nfrs[nfr] or (auditor_nfrs[nfr] != value)
          end
          if nfrs_matched
            auditor_selected = auditor
            break
          end
        end
        raise NFRMatchError.new("Could not match NFRs to an auditor") if auditor_selected.nil?
      end
      configuration = @auditors[auditor_selected]
      @auditor = auditor_selected
      return @auditor, configuration
    end

    private

    def prepend_caller_information(data)
      if 'true' == @configuration['add_caller_source_location']
        if data is_a?(Hash)
          data['caller_source_location'] = "#{caller_locations(2,1)[0]}"
        else
          caller_key_value_pair = SoarAuditingFormatter::Formatter.optional_field_format("caller_source_location","#{caller_locations(2,1)[0]}")
          data = "#{caller_key_value_pair} #{data}"
        end
      end
      data
    end

    def install_at_exit_handler
      if 'true' == @configuration['install_exit_handler']
        Kernel.at_exit do
          exit_cleanup
        end
      end
    end

    def exit_cleanup(exception = nil)
      audit_exception(exception: exception, level: :fatal, flow_id: startup_flow_id) if exception
      info("Application exit",startup_flow_id)
      flush
    end

    def audit(level, data, flow_identifier = nil)
      flow_identifier ||= @flow_id_generator.call
      formatted_data = format(level, prepend_caller_information(data), flow_identifier)
      audit_formatted(level, formatted_data)
    end

    def audit_formatted(level, data)
      if @worker
        enqueue(level, data)
      else
        auditor_caller(level, data)
      end
    end

    def enqueue(level, data)
      @worker.enqueue(level, data)
      @enqueued_audit_events += 1
    rescue AuditingOverflowError
      increase_buffer_overflow_count
      $stderr.puts "Audit buffer full, unable to audit event : #{level} : #{data}"
    end

    def increase_buffer_overflow_count
      @buffer_overflow_count += 1
    end

    def format(level, data, flow_identifier)
      if "json" == output_format
        SoarJsonAuditingFormatter::Formatter.format(level,@service_identifier,flow_identifier,Time.now.utc.iso8601(3),data)
      else
        SoarAuditingFormatter::Formatter.format(level,@service_identifier,flow_identifier,Time.now.utc.iso8601(3),data)
      end
    end

    def create_auditing_worker
      if !direct_auditor_call?
        config =  @configuration['queue_worker'] || DEFAULT_QUEUE_WORKER_CONFIG
        @worker = AuditingWorker.instance
        @worker.configure(queue_worker_configuration: config, auditor_audit_method: method(:auditor_caller))
        @worker.start
      else
        @worker = nil
      end
    end

    def auditor_caller(level, data)
      @auditor.send(level,data)
    end

    def create_auditors(configuration)
      auditor_factory = SoarConfiguredFactory::ConfiguredFactory.new(configuration['auditors'])
      auditors = {}
      configuration['auditors'].each do |auditor_name, auditor_configuration|
        raise 'Missing auditor configuration' if auditor_configuration.nil?
        auditor = create_auditor(auditor_factory,auditor_name)
        auditors[auditor] = { 'name' => auditor_name, 'nfrs' => auditor_configuration['nfrs'] }
      end
      auditors
    rescue
      $stderr.puts 'Failure initializing auditor'
      raise
    end

    def create_auditor(auditor_factory,auditor_name)
      auditor_factory.create(auditor_name)
    rescue
      $stderr.puts 'Invalid auditor configuration'
      raise
    end

    def direct_auditor_call?(configuration = @configuration)
      configuration['direct_auditor_call'] == 'true' or
        (configuration['direct_auditor_call'].nil? and @auditor.prefer_direct_call?)
    end

    def output_format
      @configuration['output_format'] || 'string'
    end

    def initialize_metrics
      @startup_timestamp     = Time.now.utc.iso8601(3)
      @enqueued_audit_events = 0
    end

    def configured_audit_level
      (@configuration["level"] || DEFAULT_LEVEL).to_sym
    end

    def verbose_status_detail
      {
        'worker' => (@worker.status_detail if @worker)
      }
    end

    def basic_status_detail
      {
        'audit_buffer_overflows' => @buffer_overflow_count,
        'enqueued_audit_events'  => @enqueued_audit_events,
        'startup_flow_id'        => startup_flow_id,
        'startup_timestamp'      => @startup_timestamp
      }
    end

    def is_valid_audit_level?(level)
      [:debug, :info, :warn, :error, :fatal].include?(level)
    end
  end
end
