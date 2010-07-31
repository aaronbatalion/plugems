# The original source of this file is here:
# gems/rails-1.1.6/lib/tasks/rails.rb
# See comments in ../plugems.rb
require "#{RAILS_ROOT}/config/environment"

$VERBOSE = nil
# Need to require environment rb from rake tasks so that plugems are initialized with plugin paths

if File.directory?("#{RAILS_ROOT}/vendor/rails")
	rails_path = "#{RAILS_ROOT}/vendor/rails/railties/lib"
else
  rails_path = $:.grep(/gems\/rails-.*\/lib/)
end

Dir["#{rails_path}/tasks/*.rake"].each { |ext| load ext }

# Load any custom rakefile extensions
Dir["#{RAILS_ROOT}/lib/tasks/**/*.rake"].sort.each { |ext| load ext }
Dir["#{RAILS_ROOT}/vendor/plugins/*/tasks/**/*.rake"].sort.each { |ext| load ext }

#Definitely load plugems own rake tasks
Dir["#{__FILE__}/../../tasks/**/*.rake"].sort.each {|ext| load ext}

# Load rake tasks from all plugems defined in application manifest
Plugems::Tasks::Loader.find_and_load
