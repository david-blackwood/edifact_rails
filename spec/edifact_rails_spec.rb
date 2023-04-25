# frozen_string_literal: true

require "spec_helper"
require "edifact_rails"

RSpec.describe EdifactRails do
  context "with a string input" do
    it "parses a single line" do
      result = described_class.parse("UNB+IATB:1+6XPPC+LHPPC+940101:0950+1'")
      expect(result).to eq([
                             ["UNB", ["IATB", 1], ["6XPPC"], ["LHPPC"], [940101, "0950"], [1]]
                           ])
    end

    it "parses multiple lines" do
      result = described_class.parse("LIN+1+1+0764569104:IB'QTY+1:25'")

      expect(result).to eq([
                             ["LIN", [1], [1], ["0764569104", "IB"]],
                             ["QTY", [1, 25]]
                           ])
    end

    it "handles escaped characters" do
      result = described_class.parse("LIN+?+?:?'??:1+A Giant?'s tale?::Does One ?+ Two = Trouble??+156")

      expect(result).to eq([["LIN", ["+:'?", 1], ["A Giant's tale:", "Does One + Two = Trouble?"], [156]]])
    end

    it "handles empty segments"

    it "handles empty data elements"

    it "handles empty data components"
  end

  context "with a file input" do
    it "returns anything"
  end
end
