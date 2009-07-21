TEST_FILES    = Dir.glob('test/test_*').delete_if { |item| item.include?( "\.svn" ) }
TEST_ASSETS   = Dir.glob('test/assets/*').delete_if { |item| item.include?( "\.svn" ) }
LIB_FILES     = Dir.glob('lib/**/*').delete_if { |item| item.include?( "\.svn" ) }
RELEASE_FILES = [ "Rakefile", "README", "MIT-LICENSE", "docs/USAGE" ] + LIB_FILES + TEST_FILES + TEST_ASSETS

Gem::Specification.new do |s|
  s.name    = "plist"
  s.version = "3.1.1"

  s.summary     = "All-purpose Property List manipulation library."
  s.description = <<-EOD
Plist is a library to manipulate Property List files, also known as plists.  It can parse plist files into native Ruby data structures as well as generating new plist files from your Ruby objects.
EOD

  s.authors  = "Ben Bleything and Patrick May"
  s.homepage = "http://plist.rubyforge.org"

  s.rubyforge_project = "plist"

  s.has_rdoc = true

  s.files      = RELEASE_FILES
  s.test_files = TEST_FILES

  s.autorequire = 'plist'
end
