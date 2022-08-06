class PDFImage

  include Webgen::PathHandler::Base

  def create_nodes(path)
    nodes = []
    nodes << create_node(path)
    pdf_path = path.dup
    pdf_path.ext = 'pdf'
    nodes << create_node(pdf_path)
    nodes
  end

  def content(node)
    create_files(node)
    if node.alcn =~ /png$/
      File.binread("#{node['file_base']}.png")
    else
      File.binread("#{node['file_base']}.pdf")
    end
  end

  private

  def create_files(node)
    source_file = "#{node['file_base']}.rb"
    png_file = "#{node['file_base']}.png"
    pdf_file = "#{node['file_base']}.pdf"

    ARGV[0] = pdf_file
    load(source_file, true)
    doc = HexaPDF::Document.open(pdf_file)
    doc.files.add(source_file, name: File.basename(source_file), description: 'Source code')
    doc.write(pdf_file, optimize: true)
    system("pdftocairo -singlefile -png -r 144 -f 1 -l 1 #{pdf_file} #{png_file[0..-5]}")
  end

end
