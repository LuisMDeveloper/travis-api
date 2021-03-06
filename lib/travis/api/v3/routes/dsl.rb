require 'travis/api/v3/routes/resource'

module Travis::API::V3
  module Routes::DSL
    def routes
      @routes ||= {}
    end

    def resources
      @resources ||= []
    end

    def current_resource
      @current_resource ||= nil
    end

    def resource(type, &block)
      resource = Routes::Resource.new(type)
      with_resource(resource, &block)
      resources << resource
    end

    def with_resource(resource)
      resource_was, @current_resource = current_resource, resource
      yield
    ensure
      @current_resource = resource_was
    end

    def route(value)
      current_resource.route = value
    end

    def get(*args)
      current_resource.add_service('GET'.freeze, *args)
    end

    def post(*args)
      current_resource.add_service('POST'.freeze, *args)
    end

    def draw_routes
      resources.each do |resource|
        prefix = resource.route
        resource.services.each do |(request_method, sub_route), service|
          route = sub_route ? prefix + sub_route : prefix
          routes[route] ||= {}
          routes[route][request_method] = Services[service]
        end
      end
      self.routes.replace(routes)
    end

    def factory_for(request_method, path)
      routes.each do |route, method_map|
        next unless params = route.params(path)
        raise MethodNotAllowed unless factory = method_map[request_method]
        return [factory, params]
      end
      nil # nothing matched
    end
  end
end
