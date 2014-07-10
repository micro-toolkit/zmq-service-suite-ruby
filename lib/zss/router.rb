module ZSS
  class Router

    def add(context, route, handler = nil)

      fail "Invalid context!" unless context
      fail "Invalid route: #{route}" unless route

      handler ||= route.to_sym

      fail "Invalid handler: #{handler}" unless context.respond_to? handler

      routes[route.to_s.upcase] = get_proc(context, handler)
    end

    def get(route)
      handler = routes[route.to_s.upcase]
      return handler if handler

      error = Error[404]
      error.developer_message = "Invalid route #{route}!"
      fail error
    end

    private

    def routes
      @routes ||= {}
    end

    def get_proc(context, handler)
      receive_headers = context.method(handler).parameters.size == 2

      if receive_headers
        Proc.new { |p,h| context.send(handler, p, h) }
      else
        Proc.new { |p,h| context.send(handler, p) }
      end
    end

  end
end
