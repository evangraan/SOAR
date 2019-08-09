# http://www.w3.org/Submission/wadl/

require "wadling/version"
#require 'byebug'

module Wadling
  class LexiconTranslator
    attr_accessor :style_sheet

    def initialize(style_sheet = "/public/wadl")
      @style_sheet = style_sheet
    end

    def translate_resources_into_wadl_files(resources, path, prefix = '')
      return empty_wadl if no_resources?(resources)
      raise ArgumentError.new("A resource dictionary is expected") if resources_invalid?(resources)
      raise ArgumentError.new("path invalid") if path_invalid?(path)
      resources.each do |r, v|
        File.open("#{path}/#{apply_prefix(v['id'], prefix)}.wadl", 'w') { |file|

          file.write(header + resources_base + translate_and_append_resource('', r, v, prefix) + resources_close + footer)
        }
      end
    end

    def translate_resources_into_wadl(resources, prefix = '')
      return empty_wadl if no_resources?(resources)
      raise ArgumentError.new("A resource dictionary is expected") if resources_invalid?(resources)
      header + resources_base + translate_resources(resources, prefix) + resources_close + footer
    end

    def header
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>" \
"<?xml-stylesheet type=\"text/xsl\" href=\"#{@style_sheet}\"?>" \
"<wadl:application xmlns:wadl=\"http://wadl.dev.java.net/2009/02\"" \
"    xmlns:jr=\"http://jasperreports.sourceforge.net/xsd/jasperreport.xsd\"" \
"    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://wadl.dev.java.net/2009/02 wadl.xsd \">"
    end

    def resources_base
      "<wadl:resources base=\"/\">"
    end

    def resources_close
      "</wadl:resources>"
    end

    def footer
      "</wadl:application>"
    end

    private

    def apply_prefix(value, prefix)
      return value if !prefix or (prefix.strip == '')
      "_#{prefix.strip}#{value}"
    end

    def path_invalid?(path)
      not File.directory?(path)
    end

    def resources_invalid?(resources)
      not resources.is_a? Hash
    end

    def translate_resources(resources, prefix)
      entries = ""
      resources.each do |r, v|
        entries = translate_and_append_resource(entries, r, v, prefix)
      end
      entries
    end

    def translate_and_append_resource(entries, r, v, prefix)
      entries, required = append_resource_header(entries, r, v, prefix)
      params = v['params'].nil? ? {} : v['params']
      params.each do |p, vv|
        entries = append_param(entries, required, p, vv)
      end
      entries = append_resource_footer(entries)
    end

    def append_resource_header(entries, r, v, prefix)
      method, required = parse_resource(r, v)
      entries = entries + "<wadl:resource path=\"#{r}\">"
      id = apply_prefix(v['id'], prefix)
      entries = entries + "  <wadl:method name=\"#{method}\" id=\"#{id}\">"
      entries = entries + "    <wadl:doc>"
      entries = entries + "      #{v['doc']}"
      entries = entries + "    </wadl:doc>"
      entries = entries + "    <wadl:request>"

      return entries, required
    end

    def append_resource_footer(entries)
      entries = entries + "    </wadl:request>"
      entries = entries + "  </wadl:method>"
      entries = entries + "</wadl:resource>"
    end

    def append_param(entries, required, p, vv)
      type = parse_param(required, p, vv)
      entries = entries + "      <wadl:param name=\"#{p}\" type=\"xsd:#{type}\" required=\"#{vv['required']}\" style=\"query\""
      entries = entries + " default=\"#{vv['default']}\"" if vv['default']
      entries = entries + ">      </wadl:param>"
    end

    def parse_resource(r, v)
      raise ArgumentError.new("Invalid resource path") if r.nil?
      raise ArgumentError.new("Resource definition invalid") if (v.nil?) or (not v.is_a?(Hash))
      method = translate_method(v['method'])
      raise ArgumentError.new("Resource documentation invalid") if v['doc'].nil? or not v['doc'].is_a? String
      raise ArgumentError.new("Resource id invalid") if v['id'].nil?
      required = translate_required(v['required'])
      return method, required
    end

    def parse_param(required, p, vv)
      type = translate_type(vv['type'])
      raise ArgumentError.new("parameter should not have a default value when required") if required and not vv['default'].nil?
      type
    end

    def no_resources?(resources)
      (resources.nil?) or (resources == {})
    end

    def empty_wadl
      header + resources_base + resources_close + footer
    end

    def translate_method(method)
      raise ArgumentError.new("Invalid method") if method.nil? or method.strip == ""
      return "GET" if (method.strip().casecmp("GET") == 0)
      return "POST" if (method.strip().casecmp("POST") == 0)
      return "PUT" if (method.strip().casecmp("PUT") == 0)
      return "DELETE" if (method.strip().casecmp("DELETE") == 0)
      raise ArgumentError.new("Invalid method")
    end

    def translate_type(type)
      raise ArgumentError.new("Parameter type invalid") if type.nil? or not type.is_a? String
      # http://www.datypic.com/sc/xsd/t-xsd_anySimpleType.html
      name = type.strip.downcase
      return name if ["string", "integer", "float", "double", "boolean", "date", "time", "anyURI"].include? name
      raise ArgumentError.new("Parameter type invalid")
    end

    def translate_required(required)
      return nil if required.nil?
      return 'true' if required == true or required.downcase.strip == 'true'
      return 'false' if required == false or required.downcase.strip == 'false'
      raise ArgumentError.new("Parameter presence indicator invalid")
    end
  end
end

