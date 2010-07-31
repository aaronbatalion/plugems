module Plugems
	module Tasks
		class Loader
			def self.find_and_load
				Plugems::Loader.gem_rake_tasks.each do |ext|
					begin
						load ext
					rescue => e
						puts "[Plugems Error]: Error (#{e}) loading rake tasks in gems #{ext}"
						e.backtrace.each do |err|
							puts "[Plugems Error]:   #{err}"
					  end
					end
				end
				puts "[plugems] - Loaded rake tasks from gem dependencies"
			end
		end
	end
end
