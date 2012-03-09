require 'yaml'
module Coursera
  # http://mjijackson.com/2010/02/flexible-ruby-config-objects
  class Config
    def initialize(data={})
      @data = {}
      update!(data)
    end

    def self.load_from_file(config_name=nil, config_file_name='config/conf.yml')
      defaults = {
        :halt => true,
        :sleep_duration => 300,
        :num_threads => 1,
      }
      conf = self.new defaults
      data = conf.send(:load_file!, config_file_name, config_name)
      conf.send(:update!, data)
      conf.send(:check_required_attributes!)
      conf
    end

    def [](key)
      sym = key.to_sym
      raise ArgumentError, "Invalid key: #{key}" unless @data.include? sym
      @data[sym]
    end

    def []=(key, value)
      if value.class == Hash
        @data[key.to_sym] = Config.new(value)
      else
        @data[key.to_sym] = value
      end
    end

    def method_missing(sym, *args)
      if sym.to_s =~ /(.+)=$/
        self[$1] = args.first
      else
        self[sym]
      end
    end

  protected

    def load_file!(file_name, config_name=nil)
      file = YAML::load(File.open(file_name, 'r'){|f| f.read})
      config_name ||= file['default'] || file.keys.first
      data = file[config_name]
      raise "Couldn't load configuration #{config_name}" if data.nil?
      data
    end

    def update!(data)
      data.each do |key, value|
        self[key] = value
      end
    end

    def check_required_attributes!
      required = [
        :endpoint_uri,
        :api_key,
        :autograders_yml,
      ]
      required.each do |attr|
        raise ArgumentError, "Missing required configuration #{attr}" unless 
          @data.include? attr
      end
    end
  end
end
