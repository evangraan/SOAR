module SoarSc
  class SoarScRouter < SoarScRouting::BaseRouter
    def not_found
      SoarSc::Web::Views::Default.not_found
    end

    def excepted(ex)
     SoarSc::Web::Views::Default.error(ex)      
    end
  end
end