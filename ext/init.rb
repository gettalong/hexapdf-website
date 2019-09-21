require 'rdoc/store' rescue require 'rdoc/rdoc'
load('tipue_search')

require_relative 'examples'
require_relative 'benchmark'
require_relative 'tutorial'

website.ext.path_handler.register(Examples, patterns: ['**/*.examples'], insert_at: 4)

option('path_handler.example_pdf.hexapdf_lib', '../hexapdf/lib')
website.ext.path_handler.register(ExamplePDF, insert_at: 4, name: 'example_pdf')

website.ext.path_handler.register(HexaPDFBenchmark, patterns: ['**/*.benchmark'], insert_at: 4)
option('path_handler.benchmark.base_dir', '../hexapdf/benchmark')

website.ext.path_handler.register(TutorialPage, insert_at: 4)
website.ext.tag.register('code', config_prefix: 'tag.code',
                         mandatory: ['range']) do |_tag, _body, context|
  range = context[:config]['tag.code.range']
  range = range..range if range.kind_of?(Numeric)
  context.node.blocks['code'].split("\n")[range].join("\n")
end
website.config.define_option('tag.code.range', nil)
