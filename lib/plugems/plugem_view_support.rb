class TemplateCache
  
  @@cache = {}
  @@caching = true
  
  def self.cache
    @@caching ? @@cache : {}
  end
  
  def self.caching=(arg)
    @@caching = arg
  end
  
end

# Plugems requires that views be loaded from gems defined in application manifest
module ActionView
	class Base
		def full_template_path(template_path, extension)
      TemplateCache.cache[ [template_path, extension] ] ||= lookup_full_template_path(template_path, extension)
		end

    def lookup_full_template_path(template_path, extension)
      default_template = "#{@base_path}/#{template_path}.#{extension}"
			return default_template if File.exist?(default_template)
			
			plugin_views = self.class.plugin_template("#{template_path}.#{extension}")
			return plugin_views.first || default_template
		end
		
		# This is cached, and maybe should not be cached in development mode. 
		def self.plugin_templates
      # Note: This does support symlinks (top-level) vendor/plugins/acts_as_funky_chicken, 
			# but not vendor/plugins/acts/acts_as_funky_bacon
			(Plugems::Loader.gem_views + Plugems::Loader.plugin_views).flatten.uniq
		end

    def self.plugin_template(file_name)
			 plugin_templates.select {|dir| dir =~ /#{file_name}/ }
	  end

		def self.plugin_layouts
			 plugin_templates.select {|dir| dir =~ /views\/layouts/ }
		end
	end
end

# action_pack/lib/action_controller/layout.rb
module ActionController 
	module Layout 
		module ClassMethods

			# Allow layouts to also exist in plugems
		  def layout_list
			  TemplateCache.cache[:layout_list_cache] ||= Dir.glob("#{template_root}/layouts/**/*") + ActionView::Base.plugin_layouts
		  end
		end

		private
		def layout_directory?(layout_name)
			TemplateCache.cache[layout_name] ||= begin
		   	template_path = File.join(self.class.view_root, 'layouts', layout_name) 
		  	dirname = File.dirname(template_path)

				# if the layout requested was not found in the application view root, look in plugem view paths
			  unless File.directory? dirname
				  plugin_layout_list = ActionView::Base.plugin_template("\/views\/layouts\/#{layout_name}.*")
				  dirname = File.dirname(plugin_layout_list.first) if plugin_layout_list.first
			  end

			  self.class.send(:layout_directory_exists_cache)[dirname]
			end
		end
	end
end
