require 'tmpdir'

class ExamplePDF

  include Webgen::PathHandler::Base

  def create_nodes(path)
    create_node(path)
  end

  def content(node)
    hexapdf_lib = File.expand_path(@website.config['path_handler.example_pdf.hexapdf_lib'])
    file = File.expand_path(node['file'])
    pdf_name = File.basename(node['file'].sub(/\.rb$/, '.pdf'))
    content = ''

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        unless system("ruby -I#{hexapdf_lib} #{file}")
          raise "Error creating example PDF file from #{node['file']}"
        end
        content = File.read(pdf_name)
      end
    end

    content
  end

end

class Examples

  include Webgen::PathHandler::Base
  include Webgen::PathHandler::PageUtils

  def create_nodes(path, blocks)
    examples_path = Webgen::Path.new(path.parent_path + path.basename + '/')
    if @website.tree[examples_path.alcn]
      examples_node = @website.tree[examples_path.alcn]
    else
      examples_path['modified_at'] = path['modified_at']
      examples_path['handler'] = 'directory'
      examples_node = @website.ext.path_handler.create_secondary_nodes(examples_path).first
    end

    Dir[path['path']].each do |file|
      create_example_node(file, examples_node)
    end

    nil
  end

  def create_example_node(file, parent_node)
    name = parent_node.alcn + File.basename(file, '.*') + '.page'
    intro, _match, code = File.read(file).partition(/\n\n/)
    intro.gsub!(/^# ?/, '')
    if intro !~ /^Usage:\s*\n.*INPUT\d*\.PDF/
      path = Webgen::Path.new(name.sub(/\.page$/, '.pdf'), 'handler' => 'example_pdf',
                              'file' => file, 'modified_at' => parent_node['modified_at'])
      node = @website.ext.path_handler.create_secondary_nodes(path).first
      @website.ext.item_tracker.add(node, :file, file)
      intro << "\n\nResulting PDF:\n: [#{path.basename}.pdf](#{node.alcn})\n"
    end

    content = "#{intro}\n\n## Code\n\n~~~ ruby\n#{code}\n~~~\n"
    title = content[/(?<=\A## ).*?(?=\n)/]
    path = Webgen::Path.new(name, 'handler' => 'page', 'modified_at' => parent_node['modified_at'],
                            'title' => title,
                            'blocks' => {'defaults' => {'pipeline' => 'kramdown,fragments'}})
    node = @website.ext.path_handler.create_secondary_nodes(path, content).first
    @website.ext.item_tracker.add(node, :file, file)
  end

end
