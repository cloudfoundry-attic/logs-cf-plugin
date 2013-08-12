require "logs-cf-plugin/log_target"

describe LogsCfPlugin::LogTarget do

  it "raises error if not passed in a 3 ids" do
    expect { described_class.new(true, true, [1]) }.to raise_error /Requires 3 ids/
    expect { described_class.new(true, true, [1, 2]) }.to raise_error /Requires 3 ids/
    expect { described_class.new(true, true, [1, 2, 3]) }.not_to raise_error
  end

  describe "ambiguous?" do
    it "returns true when user wants both organization and space logs" do
      expect(described_class.new(true, true, [1, 2, 3])).to be_ambiguous
    end

    it "return false when user wants only organization logs" do
      expect(described_class.new(true, false, [1, 2, 3])).to_not be_ambiguous
    end

    it "return false when user wants only space logs" do
      expect(described_class.new(false, true, [1, 2, 3])).to_not be_ambiguous
    end

    it "return false when user wants app logs" do
      expect(described_class.new(false, false, [1, 2, 3])).to_not be_ambiguous
    end
  end

  describe "valid?" do
    it "is valid if you ask for org unambiguously" do
      expect(described_class.new(true, false, %w(org space app)).valid?).to eql true
    end

    it "is valid if you ask for org unambiguously with no app given" do
      expect(described_class.new(true, false, ["org", "space", nil]).valid?).to eql true
    end

    it "is valid if you ask for space unambiguously" do
      expect(described_class.new(false, true, %w(org space app)).valid?).to eql true
    end

    it "is valid if you ask for space unambiguously with no app given" do
      expect(described_class.new(false, true, ["org", "space", nil]).valid?).to eql true
    end

    it "is invalid if you ask for space/org ambiguously" do
      expect(described_class.new(true, true, %w(org space app)).valid?).to eql false
    end

    it "is valid if you ask for nothing specific and have an app" do
      expect(described_class.new(false, false, %w(org space app)).valid?).to eql true
    end

    it "is invalid if you ask for nothing specific and do not have an app" do
      expect(described_class.new(false, false, ["org", "space", nil]).valid?).to eql false
    end

    it "is invalid if you ask for nothing specific and do not have an app" do
      expect(described_class.new(false, false, [nil, nil, nil]).valid?).to eql false
    end
  end

  describe "#query_params" do
    it "returns nil if the params are invalid" do
      expect(described_class.new(true, true, %w(org space app)).query_params).to eql nil
    end

    it "returns only org if org is selected" do
      expect(described_class.new(true, false, %w(org space app)).query_params).to eql(org: "org")
    end

    it "returns only org,space if space is selected" do
      expect(described_class.new(false, true, %w(org space app)).query_params).to eql(org: "org", space: "space")
    end

    it "returns org,space,app if nothing specific is selected and the params are valid" do
      expect(described_class.new(false, false, %w(org space app)).query_params).to eql(org: "org", space: "space", app: "app")
    end
  end
end
