class SilenceLogger
    def method_missing(*)
        # just eats it
    end
end

class PrettyFormatter
    def call(severity, time, program_name, message)
        "#{time.strftime('%d %b %H:%M:%S')} #{severity}: #{message}\n"
    end
end
