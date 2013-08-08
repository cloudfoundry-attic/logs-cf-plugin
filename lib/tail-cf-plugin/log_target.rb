module TailCfPlugin
  class LogTarget
    def initialize(target_organization, target_space, ids)
      raise ArgumentError, "Requires 3 ids" unless ids.size == 3
      @target_organization = target_organization
      @target_space = target_space

      @org_id = ids[0]
      @space_id = ids[1]
      @app_id = ids[2]
    end

    def ambiguous?
      @target_organization && @target_space
    end

    def valid?
      !!target
    end

    def query_params
      case target
        when :org
          {org: @org_id}
        when :space
          {org: @org_id, space: @space_id}
        when :app
          {org: @org_id, space: @space_id, app: @app_id}
      end
    end

    private

    def target
      return nil if ambiguous?
      case
        when @target_organization
          :org
        when @target_space
          :space
        when @app_id
          :app
      end
    end
  end
end
