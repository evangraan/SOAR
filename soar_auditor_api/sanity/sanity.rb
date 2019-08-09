require 'soar_auditor_api'

class SanityAuditor < SoarAuditorApi::AuditorAPI
  def configuration_is_valid?(configuration)
    return configuration.include?("preprefix")
  end

  def audit(data)
    puts @configuration["preprefix"] + data
  end
end

class TestSerializable < SoarAuditorApi::Serializable
  def to_s
    serialize
  end
end

class Main
  def test_sanity
    @iut = SanityAuditor.new
    configuration = { "preprefix" => "very important:" }
    @iut.configure(configuration)
    @iut.set_audit_level(:debug)

    some_debug_object = 123
    @iut.info("This is info")
    @iut.debug(some_debug_object)
    dropped = 95
    @iut.warn("Statistics show that dropped packets have increased to #{dropped}%")
    @iut.error("Could not resend some dropped packets. They have been lost. All is still OK, I could compensate")
    @iut.fatal("Unable to perform action, too many dropped packets. Functional degradation.")
    @iut << 'Rack::CommonLogger requires this'

    serializable_object = TestSerializable.new("some data")
    puts serializable_object.to_s

  end
end

main = Main.new
main.test_sanity
