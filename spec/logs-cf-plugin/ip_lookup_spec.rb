require "spec_helper"

describe IpLookup do
  describe "best_ip_info" do
    it "is an ip address" do
      expect(IpLookup.best_ip_info).to match /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
    end
  end
end