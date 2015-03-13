# encoding: utf-8
class SimpleHttp
    # DAFUQ
    def basic_authentication usr, pwd
        # IT WAS:
        #str = Base64.encode64("#{usr}:#{pwd}")
        #str = "Basic #{str}"
        
        #@request_headers["Authorization"]= str

        # NOW IT IS:
        @request_headers["Authorization"]= 'Basic ' + ["#{usr}:#{pwd}"].pack('m').delete("\r\n")
    end
end
