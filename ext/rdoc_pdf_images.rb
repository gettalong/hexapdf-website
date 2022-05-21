module RDocPDFImages

  TEMPLATES = {
    'canvas' => <<~SOURCE_CODE,
      require 'hexapdf'
      require 'geom2d'
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
      require 'geom2d'
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
      require 'geom2d'
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
    'small' => <<~SOURCE_CODE,
      require 'hexapdf'
      require 'geom2d'
      doc = HexaPDF::Document.new
      hp_path = '%s'
      machu_picchu = File.join(hp_path, "examples", "machupicchu.jpg")
      canvas = doc.pages.add([0, 0, 100, 100]).canvas
      canvas.save_graphics_state do
        canvas.line_width(2).line_dash_pattern(1).stroke_color("lightgray").
          line(0, 0, 100, 0).line(0, 100, 0, 0).stroke
      end

      %s

      doc.write(ARGV[0] || 'out.pdf')
    SOURCE_CODE
    'composer' => <<~SOURCE_CODE,
      require 'hexapdf'
      require 'geom2d'

      def draw_current_frame_shape(color = "black")
        $c.canvas.line_width(1).line_dash_pattern(0).
          stroke_color(color).draw(:geom2d, object: $c.frame.shape)
      end

      composer = $c = HexaPDF::Composer.new(page_size: [0, 0, 200, 200], margin: 10)
      hp_path = '%s'
      machu_picchu = File.join(hp_path, "examples", "machupicchu.jpg")
      composer.canvas.save_graphics_state.
        line_width(1).line_dash_pattern(1).
        stroke_color("lightgray").
        rectangle(10, 10, 180, 180).stroke.
        restore_graphics_state

      %s

      composer.write(ARGV[0] || 'out.pdf')
    SOURCE_CODE
    'composer100' => <<~SOURCE_CODE,
      require 'hexapdf'
      require 'geom2d'

      def draw_current_frame_shape(color = "black")
        $c.canvas.line_width(1).line_dash_pattern(0).
          stroke_color(color).draw(:geom2d, object: $c.frame.shape)
      end

      composer = $c = HexaPDF::Composer.new(page_size: [0, 0, 200, 100], margin: 10)
      hp_path = '%s'
      machu_picchu = File.join(hp_path, "examples", "machupicchu.jpg")
      composer.canvas.save_graphics_state.
        line_width(1).line_dash_pattern(1).
        stroke_color("lightgray").
        rectangle(10, 10, 180, 80).stroke.
        restore_graphics_state

      %s

      composer.write(ARGV[0] || 'out.pdf')
    SOURCE_CODE
  }


  def create_page_node_for_class(api_path, dir_node, klass, output_flag_file)
    node = super
    hexapdf_path = File.join(@website.config['path_handler.example_pdf.hexapdf_lib'], '..')

    block = lambda do |code_object|
      if code_object.kind_of?(RDoc::ClassModule)
        code_object.instance_variable_set(:@comment, RDoc::Comment.new(code_object.comment).parse)
      elsif code_object.comment.kind_of?(RDoc::Comment)
        code_object.comment = code_object.comment.parse
      end
      file_name = code_object.full_name.gsub(/:|#/, '_')
      counter = 0

      process_markup = lambda do |markup|
        list = []

        markup.parts.each_with_index do |part, index|
          if part.kind_of?(RDoc::Markup::List)
            part.items.each {|list_item| process_markup.call(list_item) }
          elsif part.kind_of?(RDoc::Markup::Document)
            process_markup.call(part)
          end
          next unless part.kind_of?(RDoc::Markup::Verbatim)

          if part.text.match?(/#>pdf/)
            template_name, modifier = part.text.scan(/(?<=#>pdf-).*/).first.to_s.split('-')
            template = TEMPLATES[template_name] || TEMPLATES["canvas"]
            part.parts[0].sub!(/\A.*?\n/, '')
            code = format(template, hexapdf_path, part.text)
            path = Webgen::Path.new(node.parent.alcn + "#{file_name}#{counter}.png",
                                    'handler' => 'pdf_image', 'file_base' => "#{file_name}#{counter}")
            @website.ext.path_handler.create_secondary_nodes(path, code).first
            list << [counter, index, modifier]
            counter += 1
          end
        end
        list.reverse_each do |counter, index, modifier|
          part = RDoc::Markup::Raw.new("<p class='pdf-#{modifier}'><a href='#{file_name}#{counter}.pdf'>" \
                                       "<img class='pdf-image' src='#{file_name}#{counter}.png' /></a></p>")
          if modifier == 'hide'
            markup.parts[index] = part
          else
            markup.parts.insert(index + 1, part)
          end
        end
      end

      process_markup.call(code_object.comment)
    end
    block.call(klass)
    klass.method_list.each(&block)
    klass.attributes.each(&block)
    klass.constants.each(&block)

    node
  end
end

class Webgen::PathHandler::Api
  prepend ::RDocPDFImages
end

