Gem::Specification.new do |s|
  s.name    = "plist"
  s.version = "3.1.6"

  s.summary     = "All-purpose Property List manipulation library."
  s.description = <<-EOD
Plist is a library to manipulate Property List files, also known as plists.  It can parse plist files into native Ruby data structures as well as generating new plist files from your Ruby objects.
EOD

  s.authors  = "Ben Bleything and Patrick May"
  s.homepage = "http://plist.rubyforge.org"

  s.rubyforge_project = "plist"

  s.has_rdoc = true

  s.files      = [
    "Rakefile",
    "README",
    "MIT-LICENSE",
    "docs/USAGE",
    "lib/plist",
    "lib/plist/binary.rb",
    "lib/plist/generator.rb",
    "lib/plist/parser.rb",
    "lib/plist.rb",
    "test/test_data_elements.rb",
    "test/test_generator.rb",
    "test/test_generator_basic_types.rb",
    "test/test_generator_collections.rb",
    "test/test_parser.rb",
    "test/assets/AlbumData.xml",
    "test/assets/commented.plist",
    "test/assets/Cookies.plist",
    "test/assets/example_data.bin",
    "test/assets/example_data.jpg",
    "test/assets/example_data.plist",
    "test/assets/test_data_elements.plist",
    "test/assets/test_empty_key.plist"
  ]
  s.test_files = [
    "test/test_data_elements.rb",
    "test/test_generator.rb",
    "test/test_generator_basic_types.rb",
    "test/test_generator_collections.rb",
    "test/test_parser.rb"
  ]
end
