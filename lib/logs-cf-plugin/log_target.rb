module LogsCfPlugin
  class LogTarget
    def initialize(app_id)
      @app_id = app_id
    end

    def valid?
      !@app_id.nil?
    end

    def query_params
      {app: @app_id}
    end

    private

    def target
      :app if @app_id
    end
  end
end
