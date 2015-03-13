# encoding: utf-8
class Component
    def initialize(context)
        @context = context
    end

    attr_reader :context

    def log
        context.clio.log
    end

    def client
        context.clio.client
    end
end
