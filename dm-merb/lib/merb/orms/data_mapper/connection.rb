require 'fileutils'
require 'data_mapper'

module Merb
  module Orms
    module DataMapper
      class << self
        def config_file() Merb.root / "config" / "database.yml" end
        def sample_dest() Merb.root / "config" / "database.yml.sample" end
        def sample_source() File.dirname(__FILE__) / "database.yml.sample" end

        def copy_sample_config
          FileUtils.cp sample_source, sample_dest unless File.exists?(sample_dest)
        end
        
        def full_config
          @full_config ||= Erubis.load_yaml_file(config_file)
        end
        
        def config
          @config ||=
            begin
            # Convert string keys to symbols
            config = (Merb::Plugins.config[:merb_datamapper] = {})
            (full_config[Merb.environment.to_sym] || full_config[Merb.environment]).each do |k, v|
              if k == 'port'
                config[k.to_sym] = v.to_i
              elsif k == 'adapter' && v == 'postgresql'
                config[k.to_sym] = 'postgres'
	      else
		config[k.to_sym] = v
              end
            end
            config
          end
        end

        # Database connects as soon as the gem is loaded
        def connect
          if File.exists?(config_file)
            start_logging            
            setup_connections
          else
            copy_sample_config
            Merb.logger.error! "No database.yml file found in #{Merb.root}/config."
            Merb.logger.error! "A sample file was created called database.sample.yml for you to copy and edit."
            exit(1)
          end
        end
        
        def start_logging
          ::DataMapper.logger = Merb.logger
          ::DataMapper.logger.info("Connecting to database...")
        end
        
        def setup_connections
          conf = config.dup
          repositories = conf.delete(:repositories)
          ::DataMapper.setup(:default, conf) unless conf.empty?
          repositories.each { |name, opts| ::DataMapper.setup(name, opts) } if repositories
        end

        # Registering this ORM lets the user choose DataMapper as a session store
        # in merb.yml's session_store: option.
        def register_session_type
          Merb.register_session_type("datamapper",
            "merb/session/data_mapper_session",
            "Using DataMapper database sessions")
        end
      end
    end
  end
end
