module LogsCfPlugin
  class LogTarget
    def initialize(app)
      @app = app
    end

    def valid?
      !app_id.nil?
    end

    def query_params
      {app: app_id}
    end

    def app_id
      @app.try(:guid)
    end

    def app_name
      @app.try(:name)
    end

    private

    def target
      :app if app_id
    end
  end
end
