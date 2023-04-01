class TutorialPage < Webgen::PathHandler::Page

  def create_nodes(path, blocks)
    if path['version'] == 'default'
      page_node = super
      page_node.blocks['content'] << <<~TEXT


      ## The Complete Code and Result PDF

      Here is the complete code generating [this result PDF](#{page_node['output_pdf']}):

      <webgen:block name="code" />
      TEXT
      page_node.blocks['code'] = "~~~ ruby\n#{code(page_node)}\n~~~\n"
      page_node
    else
      path['dest_path'] = "<parent>#{path['output_pdf']}"
      create_node(path) {|node| set_blocks(node, blocks) }
    end
  end

  def content(node)
    if node['version'] == 'default'
      super
    else
      hexapdf_lib = File.expand_path(@website.config['path_handler.example_pdf.hexapdf_lib'])
      tutorials_dir = File.join(@website.config['website.tmpdir'], 'tutorials')
      pdf_file = File.join(tutorials_dir, node['output_pdf'])
      code_file = pdf_file + '.rb'

      Dir.mkdir(tutorials_dir) unless File.directory?(tutorials_dir)
      File.write(code_file, code(node), mode: 'w')
      Dir.chdir(tutorials_dir) do
        unless system("ruby -I#{hexapdf_lib} #{File.basename(code_file)}")
          raise "Error creating tutorial PDF file from #{node.versions['default'].alcn}"
        end
      end

      File.read(pdf_file)
    end
  end

  def code(node)
    node.blocks['content'].scan(/\n~~~ ruby\n(.*?)\n~~~/m).map(&:first).join("\n\n").gsub(/\\+\{/, '{')
  end

end
