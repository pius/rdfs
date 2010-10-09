require 'rubygems'
require 'rspec'
require 'rspec/core/rake_task'
require 'rake/clean'
#require 'spec/rake/spectask'
require 'pathname'

task :default => [ :spec ]

desc 'Run specifications'

RSpec::Core::RakeTask.new(:rcov) do |t|
  t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
  t.pattern = 'spec/**/*_spec.rb'
 
  begin
    t.rcov = ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true
    t.rcov_opts << '--exclude' << 'spec'
    t.rcov_opts << '--text-summary'
    t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
  rescue Exception
    # rcov not installed
  end
end