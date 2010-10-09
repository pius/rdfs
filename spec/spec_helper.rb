require 'rubygems'
require 'pathname'
require 'rdf'
require 'rdfs'
require 'rdfs/rule'

class Pathname
  def /(path)
    (self + path).expand_path
  end
end # class Pathname

spec_dir_path = Pathname(__FILE__).dirname.expand_path
require spec_dir_path.parent + 'lib/rdfs'

# # require fixture resources
Dir[spec_dir_path + "lib/rdfs/*.rb"].each do |fixture_file|
  require fixture_file
end

# # require fixture resources
# Dir[spec_dir_path + "fixtures/*.rb"].each do |fixture_file|
#   require fixture_file
# end


require 'rspec'
# optionally add autorun support
#require 'rspec/autorun'

Rspec.configure do |c|
  c.mock_with :rspec
end