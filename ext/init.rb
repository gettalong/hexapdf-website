require 'rdoc/store' rescue require 'rdoc/rdoc'
load('tipue_search')

require_relative 'examples'

website.ext.path_handler.register(Examples, patterns: ['**/*.examples'], insert_at: 4)

option('path_handler.example_pdf.hexapdf_lib', '../hexapdf/lib')
website.ext.path_handler.register(ExamplePDF, insert_at: 4, name: 'example_pdf')
