module Travis::API::V3
  class Router
    include Travis::API::V3
    attr_accessor :routes

    def initialize(routes = Routes)
      @routes = routes
      routes.draw_routes
    end

    def call(env)
      return service_index(env) if env['PATH_INFO'.freeze] == ?/.freeze
      access_control  = AccessControl.new(env)
      factory, params = routes.factory_for(env['REQUEST_METHOD'.freeze], env['PATH_INFO'.freeze])
      env_params      = params(env)

      raise NotFound unless factory

      service         = factory.new(access_control, env_params.merge(params))
      result          = service.run
      render(result, env_params)
    rescue Error => error
      result = Result.new(:error, error)
      V3.response(result.render, 'X-Cascade'.freeze => 'pass'.freeze, status: error.status)
    end

    def render(result, env_params)
      V3.response(result.render)
    end

    def service_index(env)
      ServiceIndex.for(env, routes).render(env)
    end

    def params(env)
      request    = Rack::Request.new(env)
      params     = request.params
      media_type = request.media_type

      if media_type == 'application/json'.freeze or media_type == 'text/json'.freeze
        request.body.rewind
        json_params = env['travis.input.json'.freeze] ||= JSON.load(request.body)
        params.merge! json_params if json_params.is_a? Hash
      end

      params
    end
  end
end
