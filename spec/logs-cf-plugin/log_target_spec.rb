require "spec_helper"

describe LogsCfPlugin::LogTarget do

  describe "valid?" do
    it "is valid if app id is present" do
      expect(described_class.new(double(guid: "appId", name: "appName")).valid?).to eql true
    end
  end

  describe "#query_params" do
    it "returns app" do
      expect(described_class.new(double(guid: "appId", name: "appName")).query_params).to eql(app: "appId")
    end
  end
end
