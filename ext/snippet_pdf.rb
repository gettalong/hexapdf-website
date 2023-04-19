class SnippetPDF

  def self.call(tag, body, context)
    snippets = context.persistent['snippets'] ||=
      context.content.scan(/\n~~~ ruby\n(.*?)\n~~~/m).map {|a| a.first.gsub(/\\+\{/, '{') }
    code = context[:config]['tag.pdf.snippets'].map do |selector|
      if selector =~ /\A(\d+)-(\d+)\z/
        snippets[($1.to_i)..($2.to_i)]
      else
        snippets[selector.to_i]
      end
    end.flatten.join("\n\n")
    pdf_file_name = context[:config]['tag.pdf.filename'] || context.content_node['output_pdf']
    code.gsub!(/((["'])#{Regexp.escape(pdf_file_name)}\2)/, '$website_out || \1')

    hexapdf_path = File.join(context.website.config['path_handler.example_pdf.hexapdf_lib'], '..')
    dir = context.website.tmpdir("snippet_pdf")
    FileUtils.mkdir_p(dir)

    context.persistent['snippet_counter'] ||= -1
    counter = context.persistent['snippet_counter'] += 1
    file_name = context.content_node.lcn.tr('/.', '-') + '-' + counter.to_s
    file_base = File.join(dir, context.content_node.alcn.tr('/.', '-') + '-' + counter.to_s)
    source_file = "#{file_base}.rb"
    File.write(source_file, code) if !File.exist?(source_file) || File.read(source_file) != code

    path = Webgen::Path.new(context.content_node.parent.alcn + "#{file_name}.png",
                            'modified_at' => File.mtime(source_file),
                            'handler' => 'pdf_image', 'file_base' => file_base,
                            'pdf_page' => context[:config]['tag.pdf.page'])
    png_node, pdf_node = context.website.ext.path_handler.create_secondary_nodes(path, code)
    "<p class='pdf-image'><a href='#{context.dest_node.route_to(pdf_node)}'>" \
      "<img src='#{context.dest_node.route_to(png_node)}' /></a></p>"
  end

end
