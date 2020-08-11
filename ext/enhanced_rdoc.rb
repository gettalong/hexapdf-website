require 'rdoc/rdoc'

class RDoc::Store

  alias :old_load_all :load_all

  include RDoc::Text

  def load_all
    result = old_load_all

    require 'hexapdf'
    require 'hexapdf/cli'
    require 'hexapdf/encryption/security_handler'
    require 'hexapdf/encryption/standard_security_handler'
    require 'hexapdf/name_tree_node'
    require 'hexapdf/number_tree_node'

    mapping = Hash[*all_classes.flat_map {|klass| [klass.full_name, klass]}]

    all_classes.select do |klass|
      klass.ancestors.any? {|ancestor| !ancestor.kind_of?(String) && ancestor.full_name == 'HexaPDF::Dictionary' }
    end.each do |rdoc_class|
      klass = Object.const_get(rdoc_class.full_name)
      docs = "<h3 id='field-definitions' class='section-header'>Field Definitions</h3>\n\n"
      docs << "<table class='field-definitions striped hoverable'>"
      docs << "<thead><tr><th>Name</th><th>Type/Allowed Values</th><th>Required</th><th>Default Value</th></tr></thead>"
      klass.each_field do |name, field|
        types = field.type.map do |t|
          if t.name.start_with?('HexaPDF') && mapping[t.name]
            target = mapping[t.name].http_url('')
            source = rdoc_class.http_url('')
            link = RDoc::Markup::Formatter.gen_relative_url(source, target)
            "<a href='#{link}'>#{t}</a>"
          else
            t.name
          end
        end.join(' or ')
        allowed_values = if field.allowed_values
                           "<br/>One of: #{field.allowed_values.map(&:inspect).join(', ')}"
                         else
                           ""
                         end
        docs << "<tr>"
        docs << "<td data-label='Name'><b>#{name}</b></td>"
        docs << "<td data-label='Type'>#{types}#{allowed_values}</td>"
        docs << "<td data-label='Required'>#{field.required?}</td>"
        docs << "<td data-label='Default Value'>#{field.default.inspect}</td>"
        docs << "</tr>"
      end
      docs << "</table>"
      doc = parse(docs, 'markdown')
      doc.file = '<MEMORY>'
      rdoc_class.comment_location << doc
    end

    result
  end

end
