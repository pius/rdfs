require 'rubygems'
require 'pathname'
require 'rdf'

class Pathname
  def /(path)
    (self + path).expand_path
  end
end # class Pathname

spec_dir_path = Pathname(__FILE__).dirname.expand_path
require spec_dir_path.parent + 'lib/rdfs'



# # require fixture resources
# Dir[spec_dir_path + "fixtures/*.rb"].each do |fixture_file|
#   require fixture_file
# end
