require "spec_helper"

describe LogsCfPlugin::LogTarget do
  describe "valid?" do
    it "is valid if app id is present" do
      expect(described_class.new("appId").valid?).to eql true
    end
  end

  describe "#query_params" do
    it "returns app" do
      expect(described_class.new("appId").query_params).to eql(app: "appId")
    end
  end
end
