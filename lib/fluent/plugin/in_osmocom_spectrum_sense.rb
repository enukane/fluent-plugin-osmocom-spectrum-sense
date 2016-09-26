require "fluent/input"
require "fluent/parser"

module Fluent
  class OsmocomSpectrumSenseInput < Input
    Plugin.register_input('osmocom_spectrum_sense', self)
    require 'open3'
    require 'time'

    def initialize
      super
    end

    config_param :tag, :string, :default => "osmocom"
    config_param :minfreq, :integer, :default => nil
    config_param :maxfreq, :integer, :default => nil
    config_param :sample_rate, :integer, :default => 3200000
    config_param :dwell_delay, :float, :default => 0.25
    config_param :tune_delay, :float, :default => 0.25
    config_param :channel_bandwidth, :float, :default => 6250.0

    def configure(conf)
      super

      if !@minfreq.is_a?(Integer) or !@maxfreq.is_a?(Integer)
        raise ConfigError, "minfreq/maxfreq is required to be Integer"
      end
    end

    def start
      super

      @thread = Thread.new(&method(:run))
    end

    def shutdown
      if @th_osmocom and @th_osmocom.alive?
        Process.kill("INT", @th_osmocom.pid)
      end
      @thread.join
    rescue => e
      log.error "osmocom_spectrum_sense failed to shutdown", :error => e.to_s,
        :error_class => e.class.to_s
      log.error_backtrace e.backtrace
    end

    def run
      options = build_options
      cmdline = "osmocom_spectrum_sense #{options}"
      print cmdline + "\n"
      stdin, stdout, stderr, @th_osmocom = *Open3.popen3(cmdline)

      while @th_osmocom.alive?
        collect_osmocom_output(stdout)
      end
    rescue => e
      log.error "unexpected error", :error => e.to_s
      log.error_backtrace e.backtrace
    end

    def build_options
      options = ""
      if @sample_rate
        options += " -s #{@sample_rate}"
      end
      if @dwell_delay
        options += " --dwell-delay=#{@dwell_delay}"
      end
      if @tune_delay
        options += " --tune-delay=#{@tune_delay}"
      end
      if @channel_bandwidth
        options += " -b #{@channel_bandwidth}"
      end

      options += " #{@minfreq} #{@maxfreq}"
      return options
    end

    REG=/^(?<time>.+) center_freq (?<center_freq>\d+\.\d+) freq (?<freq>\d+\.\d+) power_db (?<power_db>-?\d+\.\d+) noise_floor_db (?<noise_floor_db>-?\d+\.\d+)$/
    def collect_osmocom_output(stdout)
      collected = []
      begin
        readlines_nonblock(stdout).each do |line|
          # XXX: parse here
          log.debug "line => '#{line}'"
          match = line.match(REG)
          next unless match
          obj = {
            "updated_at" => Time.parse(match[:time]),
            "center_freq" => match[:center_freq].to_f,
            "freq" => match[:freq].to_f,
            "power_db" => match[:power_db].to_f,
            "noise_floor_db" => match[:noise_floor_db].to_f,
          }
          log.debug "new osmocom_spectrum_sense input => #{obj}"
          collected << obj
        end
      rescue => e
        log.error "failed to read or parse line", :error => e.to_s,
          :error_class => e.class.to_s
      end

      collected.each do |obj|
        time = obj["updated_at"].nil? ? Engine.now : Fluent::EventTime.from_time(obj["updated_at"])
        if obj["updated_at"].is_a?(Time)
          obj["updated_at"] = obj["updated_at"].strftime("%Y-%m-%d %H:%M:%S.%6N")
        end
        router.emit(@tag, time, obj)
      end
    rescue => e
      log.error "failed to collect output from tshark",
        :error => e.to_s,
        :error_class => e.class.to_s
    end

    def readlines_nonblock(io)
      @nbbuffer = "" if @nbbuffer == nil
      @nbbuffer += io.read_nonblock(65535)
      lines = []
      while idx = @nbbuffer.index("\n")
        lines << @nbbuffer[0..idx-1]
        @nbbuffer = @nbbuffer[idx+1..-1]
      end
      return lines
    rescue
      return []
    end

  end
end
