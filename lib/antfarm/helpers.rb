module Antfarm
  module Helpers
    # Symbolic marker points on the fuzzy logic certainty factor scale.
    # Certainty Factors (CF)
    CF_PROVEN_TRUE   =  1.0000
    CF_LIKELY_TRUE   =  0.5000
    CF_LACK_OF_PROOF =  0.0000
    CF_LIKELY_FALSE  = -0.5000
    CF_PROVEN_FALSE  = -1.0000

    # Amount by which a value can differ and still be considered the same.
    # Mainly used as a buffer against floating point round-off errors.
    CF_VARIANCE      =  0.0001

    @user_dir        = nil
    @logger_callback = nil
    class << self
      attr_accessor :user_dir
      attr_accessor :logger_callback
    end

    def self.clamp(x, low = CF_PROVEN_FALSE, high = CF_PROVEN_TRUE)
      if x < low
        return low
      elsif x > high
        return high
      else
        return x
      end
    end

    def self.simplify_interfaces
      #TODO
    end

    def self.timestamp
      return Time.now.utc.xmlschema
    end

    def self.log(level, *msg)
      @logger_callback.call(level, msg.join) if @logger_callback
    end

    def self.db_dir
      return File.expand_path("#{self.user_dir}/db")
    end

    def self.db_file(environment)
      return File.expand_path("#{self.user_dir}/db/#{environment}.db")
    end

    def self.log_dir
      return File.expand_path("#{self.user_dir}/log")
    end

    def self.log_file(environment)
      return File.expand_path("#{self.user_dir}/log/#{environment}.log")
    end

    def self.defaults_file
      return File.expand_path("#{self.user_dir}/config/defaults.yml")
    end

    def self.history_file
      return File.expand_path("#{self.user_dir}/history")
    end

    def self.user_plugins_dir
      return File.expand_path("#{self.user_dir}/plugins")
    end

    #######
    private
    #######

    USER_DIRECTORIES = ['config', 'db', 'log', 'plugins']

    def self.user_dir
      return @user_dir unless @user_dir.nil?
      return self.create_user_directory
    end

    # Initializes a suitable directory structure for the user
    def self.create_user_directory
      USER_DIRECTORIES.each do |directory|
        path = "#{ENV['HOME']}/.antfarm/#{directory}"
        # Just to be safe... don't want to wipe out existing user data!
        unless File.exists?(path)
          FileUtils.makedirs(path)
          Antfarm::Helpers.log :info, "User '#{directory}' directory created in #{ENV['HOME'] + '/.antfarm'}"
        end
      end

      defaults_file = "#{ENV['HOME']}/.antfarm/config/defaults.yml"
      # Just to be safe... don't want to wipe out existing user data!
      unless File.exists?(defaults_file)
        File.open(defaults_file, 'w') do |file|
          file.puts '---'
          file.puts 'environment: antfarm'
          file.puts 'log_level: warn'
        end
        Antfarm::Helpers.log :info, "Default config file created at #{ENV['HOME'] + '/.antfarm/config/defaults.yml'}"
      end

      return @user_dir = (ENV['HOME'] + '/.antfarm').dup
    end
  end
end
