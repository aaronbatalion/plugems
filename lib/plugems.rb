module RailsVersionVerifier
  ver = Rails::VERSION::STRING.split('.').collect{ |n| n.to_i }.extend(Comparable)
  fail("The rails version #{ Rails::VERSION::STRING } is not supported by plugems") unless (ver >= [1,1,6] && ver <= [1,2,3])
end
# Rails 1.1.16 is not very extensible in how it loads rake tasks.
# There is a file called tasks/rails.rb, required from the default RAILS_ROOT/Rakefile,
# that has 3 lines of Dir['foo'].each {|a| load a}, which is not very extensible
# Therefore, plugems unshifts the current lib directory in order to include a plugem
# copy of tasks/rails.rb.
$:.unshift File.dirname(__FILE__)

if defined?(RAILS_ROOT)
  require 'plugems/loader'

  module Rails
  	class Initializer

  		def load_plugins_with_plugems
  			Plugems::Loader.load(configuration)
  			load_plugins_without_plugems
  		end

  		# TODO replace with alias_method_chain on Rails 1.2
  		# alias_method_chain :load_plugins, :plugems
  		alias_method :load_plugins_without_plugems, :load_plugins
  		alias_method :load_plugins, :load_plugins_with_plugems
  	end
  end
end

module Gem
  
  class << self
  
    def activate_plugin_or_gem(gem, autorequire, *version_requirements)
      if Plugems::Loader.plugin?(gem)
  			Plugems::Loader.load_as_plugin(gem)
  		else
  			activate_gem(gem, autorequire, *version_requirements)
  		end
    end
  
    alias_method :activate_gem, :activate
    alias_method :activate, :activate_plugin_or_gem

  end

end
