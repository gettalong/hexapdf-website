module RDocPDFImages

  TEMPLATES = {
    'canvas' => <<~SOURCE_CODE,
      require 'hexapdf'
      doc = HexaPDF::Document.new
      hp_path = '%s'
      machu_picchu = File.join(hp_path, "examples", "machupicchu.jpg")
      canvas = doc.pages.add([0, 0, 200, 200]).canvas
      canvas.save_graphics_state do
        canvas.line_width(2).line_dash_pattern(1).stroke_color("lightgray").
          line(-200, 0, 200, 0).line(0, 200, 0, -200).stroke
      end

      %s

      doc.write(ARGV[0] || 'out.pdf')
    SOURCE_CODE
    'center' => <<~SOURCE_CODE,
      require 'hexapdf'
      doc = HexaPDF::Document.new
      hp_path = '%s'
      machu_picchu = File.join(hp_path, "examples", "machupicchu.jpg")
      canvas = doc.pages.add([0, 0, 200, 200]).canvas
      canvas.translate(100, 100)
      canvas.save_graphics_state do
        canvas.line_width(1).line_dash_pattern(1).stroke_color("lightgray").
          line(-200, 0, 200, 0).line(0, 200, 0, -200).stroke
      end

      %s

      doc.write(ARGV[0] || 'out.pdf')
    SOURCE_CODE
    'big' => <<~SOURCE_CODE,
      require 'hexapdf'
      doc = HexaPDF::Document.new
      hp_path = '%s'
      machu_picchu = File.join(hp_path, "examples", "machupicchu.jpg")
      canvas = doc.pages.add([0, 0, 400, 400]).canvas
      canvas.save_graphics_state do
        canvas.line_width(2).line_dash_pattern(1).stroke_color("lightgray").
          line(0, 0, 400, 0).line(0, 400, 0, 0).stroke
      end

      %s

      doc.write(ARGV[0] || 'out.pdf')
    SOURCE_CODE
  }


  def create_page_node_for_class(api_path, dir_node, klass, output_flag_file)
    node = super
    hexapdf_path = File.join(@website.config['path_handler.example_pdf.hexapdf_lib'], '..')

    block = lambda do |code_object|
      code_object.comment = code_object.comment.parse if code_object.comment.kind_of?(RDoc::Comment)
      list = []
      file_name = code_object.full_name.gsub(/:|#/, '_')
      code_object.comment.each_with_index do |part, index|
        next unless part.kind_of?(RDoc::Markup::Verbatim)
        if part.text.match?(/#>pdf/)
          template = TEMPLATES[part.text.scan(/(?<=#>pdf-).*/).first] || TEMPLATES["canvas"]
          part.parts[0].sub!(/\A.*?\n/, '')
          code = format(template, hexapdf_path, part.text)
          path = Webgen::Path.new(node.parent.alcn + "#{file_name}#{index}.png",
                                  'handler' => 'pdf_image', 'file_base' => "#{file_name}#{index}")
          @website.ext.path_handler.create_secondary_nodes(path, code).first
          list << index
        end
      end
      list.reverse_each do |index|
        part = RDoc::Markup::Raw.new("<p>Output (click the image to view the PDF with embedded " \
                                     "source file):</p><p><a href='#{file_name}#{index}.pdf'>" \
                                     "<img class='pdf-image' src='#{file_name}#{index}.png' /></a></p>")
        code_object.comment.parts.insert(index + 1, part)
      end
    end
    klass.method_list.each(&block)
    klass.constants.each(&block)

    node
  end
end

class Webgen::PathHandler::Api
  prepend ::RDocPDFImages
end

