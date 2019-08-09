require './spec/spec_helper.rb'

describe Wadling do
  def copy_hash(hash)
    Marshal.load(Marshal.dump(hash))
  end

  before :all do
    @iut = Wadling::LexiconTranslator.new
    @wadl_header = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><?xml-stylesheet type=\"text/xsl\" href=\"/public/wadl\"?><wadl:application xmlns:wadl=\"http://wadl.dev.java.net/2009/02\"    xmlns:jr=\"http://jasperreports.sourceforge.net/xsd/jasperreport.xsd\"    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://wadl.dev.java.net/2009/02 wadl.xsd \"><wadl:resources base=\"/\">"
    @wadl_footer = "</wadl:resources>" \
                   "</wadl:application>"
    @empty_wadl = @wadl_header + @wadl_footer
    @resource1 = { '/resource1' => {
                     'doc' => 'This returns resource1 for the identifier provided',
                     'method' => 'GET',
                     'id' => 'resource1',
                     'params' => {
                       'identifier' => {
                         'required' => 'false',
                         'type' => 'string',
                         'default' => '123' }}}}
    @resource2 = { '/resource2' => {
                     'doc' => 'This sets resource2 for the identifier provided to the value provided',
                     'method' => 'POST',
                     'id' => 'resource2',
                     'params' => { 
                       'identifier' => {
                         'required' => 'false',
                         'type' => 'string',
                         'default' => '123' },
                       'field2' => {
                         'required' => 'true',
                         'type' => 'string' }}}}
    @resource1_wadl = "<wadl:resource path=\"/resource1\">" \
                      "  <wadl:method name=\"GET\" id=\"resource1\">" \
                      "    <wadl:doc>" \
                      "      This returns resource1 for the identifier provided" \
                      "    </wadl:doc>" \
                      "    <wadl:request>" \
                      "      <wadl:param name=\"identifier\" type=\"xsd:string\" required=\"false\" style=\"query\" default=\"123\">" \
                      "      </wadl:param>" \
                      "    </wadl:request>" \
                      "  </wadl:method>" \
                      "</wadl:resource>"
    @resource2_wadl = "<wadl:resource path=\"/resource2\">" \
                      "  <wadl:method name=\"POST\" id=\"resource2\">" \
                      "    <wadl:doc>" \
                      "      This sets resource2 for the identifier provided to the value provided" \
                      "    </wadl:doc>" \
                      "    <wadl:request>" \
                      "      <wadl:param name=\"identifier\" type=\"xsd:string\" required=\"false\" style=\"query\" default=\"123\">" \
                      "      </wadl:param>" \
                      "      <wadl:param name=\"field2\" type=\"xsd:string\" required=\"true\" style=\"query\">" \
                      "      </wadl:param>" \
                      "    </wadl:request>" \
                      "  </wadl:method>" \
                      "</wadl:resource>"
    @wadl1 = @wadl_header + @resource1_wadl + @wadl_footer
    @wadl2 = @wadl_header + @resource1_wadl + @resource2_wadl + @wadl_footer
  end

  context "when initialize" do
    it "should default to /public/wadl for the stylesheet if none is provided" do
      expect(@iut.style_sheet).to eq("/public/wadl")
    end

    it "should remember the stylesheet is one is provided" do
      iut = Wadling::LexiconTranslator.new("/some/stylesheet")
      expect(iut.style_sheet).to eq("/some/stylesheet")
    end
  end

  context "when given nil" do
    it "should return an empty WADL descriptor" do
      expect(@iut.translate_resources_into_wadl(nil)).to eq(@empty_wadl)
    end
  end

  context "when given an empty dictionary" do
    it "should return an empty WADL descriptor" do
      expect(@iut.translate_resources_into_wadl(nil)).to eq(@empty_wadl)
    end
  end

  context "when given a non-dictionary" do
    it "should raise an ArgumentError indicating a dictionary is required" do
      expect {
        @iut.translate_resources_into_wadl([])
      }.to raise_error ArgumentError, "A resource dictionary is expected"
    end
  end

  context "when given a dictionary with resources" do
    context "when given one resource" do
      it "should return a WADL definition for that resource" do
        expect(@iut.translate_resources_into_wadl(@resource1)).to eq(@wadl1)
      end
    end

    context "when given multiple resources" do
      it "should return a WADL definition for all resources" do
        test = {}
        test = test.merge(@resource1)
        test = test.merge(@resource2)
        expect(@iut.translate_resources_into_wadl(test)).to eq(@wadl2)
      end
    end

    context "when a resource is ill-defined" do
      it "should raise an ArgumentError with appropriate descrition of the error" do
        expect {
          test = { nil => {
                   'doc' => 'This returns resource1 for the identifier provided' }}
          @iut.translate_resources_into_wadl(test)
        }.to raise_error(ArgumentError, "Invalid resource path")
        expect {
          test = { '/resource' => 2 }
          @iut.translate_resources_into_wadl(test)
        }.to raise_error(ArgumentError, "Resource definition invalid")
        expect {
          test = copy_hash(@resource1)
          test['/resource1']['doc'] = nil
          @iut.translate_resources_into_wadl(test)
        }.to raise_error(ArgumentError, "Resource documentation invalid")
        expect {
          test = copy_hash(@resource1)
          test['/resource1']['method'] = nil
          @iut.translate_resources_into_wadl(test)
        }.to raise_error(ArgumentError, "Invalid method")
        expect {
          test = copy_hash(@resource1)
          test['/resource1']['method'] = 'invalid'
          @iut.translate_resources_into_wadl(test)
        }.to raise_error(ArgumentError, "Invalid method")
        expect {
          test = copy_hash(@resource1)
          test['/resource1']['id'] = nil
          @iut.translate_resources_into_wadl(test)
        }.to raise_error(ArgumentError, "Resource id invalid")
        expect {
          test = copy_hash(@resource1)
          test['/resource1']['required'] = 'invalid'
          @iut.translate_resources_into_wadl(test)
        }.to raise_error(ArgumentError, "Parameter presence indicator invalid")
        expect {
          test = copy_hash(@resource1)
          test['/resource1']['params']['identifier']['type'] = 'invalid'
          @iut.translate_resources_into_wadl(test)
        }.to raise_error(ArgumentError, "Parameter type invalid")
        expect {
          test = copy_hash(@resource1)
          test['/resource1']['required'] = 'true'
          test['/resource1']['default'] = 'one'
          @iut.translate_resources_into_wadl(test)
        }.to raise_error(ArgumentError, "parameter should not have a default value when required")
      end
    end
  end
end
