# frozen_string_literal: true

require "spec_helper"
require "edifact_rails"
require 'byebug'

FILES_DIR = File.dirname(__FILE__) + "/test_files"

RSpec.describe EdifactRails do
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
    result = described_class.parse("LIN+?+?:?'??:1+A Giant?'s tale?::Does One ?+ Two = Trouble????+156")

    expect(result).to eq([["LIN", ["+:'?", 1], ["A Giant's tale:", "Does One + Two = Trouble??"], [156]]])
  end

  it "handles empty segments" do
    result = described_class.parse("QTY+1''QTY+2")

    expect(result).to eq([
      ['QTY', [1]],
      [],
      ['QTY', [2]]
    ])
  end

  it "handles empty data elements" do
    result = described_class.parse("FTX+AFM+1++Java Server Programming'")

    expect(result).to eq([
      ['FTX', ['AFM'], [1], [], ['Java Server Programming']]
    ])
  end

  it "handles empty data components" do
    result = described_class.parse("PDI++C:3+Y::3+F::1+A'")

    expect(result).to eq([
      ['PDI', [], ['C', 3], ['Y', nil, 3], ['F', nil, 1], ['A']]
    ])
  end

  it "parses a file" do
    result = described_class.parse_file("#{FILES_DIR}/seperate_lines.edi")
    expected = [
      ['UNB', ["UNOA", 3], ["TESTPLACE", 1], ["DEP1", 1], [20051107, 1159], [6002]],
      ['UNH', ["SSDD1"], ["ORDERS", "D", "03B", "UN", "EAN008"]],
      ['BGM', [220], ["BKOD99"], [9]],
      ['DTM', [137, 20051107, 102]],
      ['NAD', ["BY"], [5412345000176, nil, 9]],
      ['NAD', ["SU"], [4012345000094, nil, 9]],
      ['LIN', [1], [1], ["0764569104", "IB"]],
      ['QTY', [1, 25]],
      ['FTX', ["AFM"], [1], [], ["XPath 2.0 Programmer's Reference"]],
      ['LIN', [2], [1], ["0764569090", "IB"]],
      ['QTY', [1, 25]],
      ['FTX', ["AFM"], [1], [], ["XSLT 2.0 Programmer's Reference"]],
      ['LIN', [3], [1], [1861004656, "IB"]],
      ['QTY', [1, 16]],
      ['FTX', ["AFM"], [1], [], ["Java Server Programming"]],
      ['LIN', [4], [1], ["0596006756", "IB"]],
      ['QTY', [1, 10]],
      ['FTX', ["AFM"], [1], [], ["Enterprise Service Bus"]],
      ['UNS', ["S"]],
      ['CNT', [2, 4]],
      ['UNT', [22], ["SSDD1"]],
      ['UNZ', [1], [6002]]
    ]

    expect(result).to eq(expected)
  end
end
