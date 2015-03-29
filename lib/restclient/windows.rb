module RestClient
  module Windows
  end
end

if RestClient::Platform.windows?
# don't need this! so, don't need ffi gem
#  require_relative './windows/root_certs'
    module RestClient::Windows
        module RootCerts
            def self.instance; [] end
        end
    end
end
