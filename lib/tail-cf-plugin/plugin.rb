module TailCfPlugin
  class Plugin < CF::CLI
    def precondition
      # skip all default preconditions
    end

    desc "Tail a CF application's logs"
    group :apps
    def tail
      puts "Hello from tail"
    end
  end
end
