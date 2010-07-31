require 'plugems/manifest'
require 'plugems/tasks/loader'

# load monkey patch for finding views in plugins + gems too
require 'plugems/plugem_view_support.rb'

module Plugems
  class Loader

    module ClassMethods

      def load(configuration)
        # TODO find a way to get the plugin_paths defined in the Rails::Initializer block, if any
        #@@configuration = configuration
        @@loaded_plugems = {} # hash of all loaded plugems, to prevent loading duplicates

        manifest = Plugems::Manifest.load("#{RAILS_ROOT}/config/manifest.yml")
        load_plugems(manifest)
        set_dependencies_loaded_flag
      end

      def gem_rake_tasks
        (@@gem_rake_tasks ||= []).flatten.uniq
      end

      def gem_views
        (@@gem_views ||= []).flatten.uniq
      end

      def plugin_views
        plugin_lib_paths.collect do |plugin_path|
          Dir["#{plugin_path}/views/**/*.*"]
        end.flatten.uniq
      end

      def plugin?(name)
        (path = plugin_path(name)) && File.directory?(path)
      end

      def load_as_plugin(gem)
        debug "Plugin #{gem}"
        path = plugin_path(gem)
        plugin_lib = File.join(path, "lib")
        $: << plugin_lib if File.exist?(plugin_lib)
        process_plugin_manifest(path)
        require_gem_file(gem)
      end

      private 

      def plugin_lib_paths
        # TODO determine if the configuration object is already configured by this point
        #(@config ||= Rails::Configuration.new).plugin_paths.collect do |plugin_path|
          # Cant use Dir["foo/**/lib"] because symlinks are not followed with Dir
          Dir["#{RAILS_ROOT}/vendor/plugins/*"].collect { |plugin_lib| plugin_lib}.flatten.uniq
        #end.flatten.uniq
      end

      def load_plugems(manifest)
        # after loading the gem specific dependencies require 
        # each file picking up gems and plugins.  This is loaded outside the above loop
        # incase of a dependency cycle...
        manifest.dependencies.each do |name, version|
          load_plugem(name, version || ">= 0.0.0")
        end
      end

      def load_plugem(name, version)
        return if @@loaded_plugems.include?(name)

        # check if rails is frozen and skip all rails gems
        if (name == "rails" or name == "plugems") and File.exist?("#{RAILS_ROOT}/vendor/rails")
          if name == "plugems"
            require "#{RAILS_ROOT}/vendor/rails/plugems/lib/plugems/manifest"
            require "#{RAILS_ROOT}/vendor/rails/plugems/lib/plugems/plugem_view_support"
          end
          return
        end

        debug "  Looking for #{name} with #{version}..."
        if plugin?(name)
          load_as_plugin(name)
        else
          load_as_gem(name,version)
        end
        @@loaded_plugems[name] = true
      end

      def require_gem_file(gem_or_plugin)
        name = gem_or_plugin.respond_to?(:name) ? gem_or_plugin.name : gem_or_plugin 
        file = File.join(plugin_path(gem_or_plugin), "lib", name + '.rb')
        if File.exist?(file)
          require file 
          debug "Requiring '#{ file }.rb'"
        end
      end

      def plugin_path(gem_or_plugin)
        name = gem_or_plugin.respond_to?(:name) ? gem_or_plugin.name : gem_or_plugin 
        plugin_lib_paths.grep(/\/#{name}(-([\.0-9])+)?$/).first
      end

      def process_plugin_manifest(path)
        plugin_manifest_file = File.join(path, "config", "manifest.yml")
        debug "Manifest: #{plugin_manifest_file}" 
        if File.exists?(plugin_manifest_file)
          plugin_manifest = Plugems::Manifest.load(plugin_manifest_file)
          load_plugems(plugin_manifest)
        end
      end

      def load_as_gem(name, version)
        debug "Gem: #{name}"

        begin
          gem = Gem.cache.search(/^#{name}$/, version).last rescue nil #RubyGems api specifies that the result is sorted by version
          raise Gem::LoadError unless gem
          require_gem gem.name, gem.version.version
          append_rake_tasks!(gem.full_gem_path)
          append_gem_views!(gem.full_gem_path)

          debug "Gem: #{name} - Found: (#{gem.version.version})"
        rescue Gem::LoadError, Gem::Exception => gem_load_error
          error "#{name} - Searching: (#{version}), but found: (#{gem.version.version rescue "Unknown"})"
          error "#{gem_load_error}"
          error "use BOOT_DEBUG=true to show more information."
          exit(1)
        rescue Exception => error
          error "#{error}"
          error.backtrace[0..8].each do |stacktrace|
            error "    #{stacktrace}"
          end
          exit(1)
        end

      end

      def debug(msg)
        puts "[Plugems Debug]: #{msg}" if ENV['BOOT_DEBUG']
      end

      def error(msg)
        puts "[Plugems Error]: #{msg}"
      end

      def set_dependencies_loaded_flag
        # TODO: fix rhg_configuration to use Rails::Initializer.all_dependencies_loaded?
        Object.const_set('DEPENDENCIES_LOADED', true) unless defined?(DEPENDENCIES_LOADED)
      end

      def append_gem_views!(path)
        views = Dir["#{path}/views/**/*.*"]
        (@@gem_views ||= []) << views unless views.blank?
      end

      def append_rake_tasks!(path)
        tasks = Dir["#{path}/tasks/**/*.rake"].reject {|tsk| tsk=~/bootstrap|rails/}
        (@@gem_rake_tasks ||= []) << tasks unless tasks.blank?
      end

    end

    extend ClassMethods
  end
end
