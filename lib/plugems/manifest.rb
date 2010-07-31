require 'yaml'
require 'erb'
module Plugems
	class Manifest

		attr_accessor :manifest

    [:name, :version, :description, :author, :executables].each do |property|
      define_method(property) { manifest[property] }
    end
    
		def initialize(file_name = nil)
			begin
				@manifest = load_file(file_name || self.class.manifest_file)
			rescue Exception => e
				puts "#{e}. Manifest file is not set? (via Plugems::Manifest.manifest_file =)"
				puts e
			end
		end

		def dependencies
			manifest[:dependencies] || []
		end

		module ClassMethods
		  
		  @@manifest_file = nil
			
			def manifest_file
				 @@manifest_file || default_manifest_file
			end

			def load(file_name)
				new(file_name)
			end

			def default_manifest_file
			  "#{RAILS_ROOT}/config/manifest.yml"
			end

			def manifest_file=(file)
			   @@manifest_file = file
		  end
		  
		end

		extend ClassMethods
		
	private
		  
		  def load_file(file)
		    YAML.load(ERB.new(IO.read(file)).result)
	    end

	end

end
