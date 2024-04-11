# frozen_string_literal: true

require "spec_helper"
require "edifact_rails"
require "byebug"

FILES_DIR = "#{File.dirname(__FILE__)}/test_files".freeze

RSpec.describe EdifactRails do
  it "parses a single line" do
    result = described_class.parse("UNB+IATB:1+6XPPC+LHPPC+940101:0950+1'")
    expected = [
      ["UNB", ["IATB", 1], ["6XPPC"], ["LHPPC"], [940101, "0950"], [1]]
    ]

    expect(result).to eq(expected)
  end

  it "parses multiple lines" do
    result = described_class.parse("LIN+1+1+0764569104:IB'QTY+1:25'")
    expected = [
      ["LIN", [1], [1], ["0764569104", "IB"]],
      ["QTY", [1, 25]]
    ]

    expect(result).to eq(expected)
  end

  it "parses escaped characters" do
    result = described_class.parse("LIN+?+?:?'??:1+A Giant?'s tale?::Does One ?+ Two = Trouble????+156'")
    expected = [
      ["LIN", ["+:'?", 1], ["A Giant's tale:", "Does One + Two = Trouble??"], [156]]
    ]
    expect(result).to eq(expected)
  end

  it "parses empty segments" do
    result = described_class.parse("QTY+1''QTY+2'")
    expected = [
      ["QTY", [1]],
      [],
      ["QTY", [2]]
    ]

    expect(result).to eq(expected)
  end

  it "parses empty data elements" do
    result = described_class.parse("FTX+AFM+1++Java Server Programming'")
    expected = [
      ["FTX", ["AFM"], [1], [], ["Java Server Programming"]]
    ]

    expect(result).to eq(expected)
  end

  it "parses empty data components" do
    result = described_class.parse("PDI++C:3+Y::3+F::1+A'")
    expected = [
      ["PDI", [], ["C", 3], ["Y", nil, 3], ["F", nil, 1], ["A"]]
    ]

    expect(result).to eq(expected)
  end

  it "parses a file" do
    result = described_class.parse_file("#{FILES_DIR}/seperate_lines.edi")
    expected = [
      ["UNB", ["UNOA", 3], ["TESTPLACE", 1], ["DEP1", 1], [20051107, 1159], [6002]],
      ["UNH", ["SSDD1"], ["ORDERS", "D", "03B", "UN", "EAN008"]],
      ["BGM", [220], ["BKOD99"], [9]],
      ["DTM", [137, 20051107, 102]],
      ["NAD", ["BY"], [5412345000176, nil, 9]],
      ["NAD", ["SU"], [4012345000094, nil, 9]],
      ["LIN", [1], [1], ["0764569104", "IB"]],
      ["QTY", [1, 25]],
      ["FTX", ["AFM"], [1], [], ["XPath 2.0 Programmer's Reference"]],
      ["LIN", [2], [1], ["0764569090", "IB"]],
      ["QTY", [1, 25]],
      ["FTX", ["AFM"], [1], [], ["XSLT 2.0 Programmer's Reference"]],
      ["LIN", [3], [1], [1861004656, "IB"]],
      ["QTY", [1, 16]],
      ["FTX", ["AFM"], [1], [], ["Java Server Programming"]],
      ["LIN", [4], [1], ["0596006756", "IB"]],
      ["QTY", [1, 10]],
      ["FTX", ["AFM"], [1], [], ["Enterprise Service Bus"]],
      ["UNS", ["S"]],
      ["CNT", [2, 4]],
      ["UNT", [22], ["SSDD1"]],
      ["UNZ", [1], [6002]]
    ]

    expect(result).to eq(expected)
  end

  it "parses a file with different special characters defined" do
    result = described_class.parse_file("#{FILES_DIR}/seperate_lines_different_special_characters.edi")
    expected = [
      ["UNB", ["UNOA", 3], ["TESTPLACE", 1], ["DEP1", 1], [20051107, 1159], [6002]],
      ["UNH", ["SSDD1"], ["ORDERS", "D", "03B", "UN", "EAN008"]],
      ["BGM", [220], ["BKOD99"], [9]],
      ["DTM", [137, 20051107, 102]],
      ["NAD", ["BY"], [5412345000176, nil, 9]],
      ["NAD", ["SU"], [4012345000094, nil, 9]],
      ["LIN", [1], [1], ["0764569104", "IB"]],
      ["QTY", [1, 25]],
      ["FTX", ["AFM"], [1], [], ["Here's a string with some escaped special characters: !^\\~"]],
      ["LIN", [2], [1], ["0764569090", "IB"]],
      ["QTY", [1, 25]],
      ["FTX", ["AFM"], [1], [], ["XSLT 2.0 Programmer's Reference"]],
      ["LIN", [3], [1], [1861004656, "IB"]],
      ["QTY", [1, 16]],
      ["FTX", ["AFM"], [1], [], ["Java Server Programming"]],
      ["LIN", [4], [1], ["0596006756", "IB"]],
      ["QTY", [1, 10]],
      ["FTX", ["AFM"], [1], [], ["Enterprise Service Bus"]],
      ["UNS", ["S"]],
      ["CNT", [2, 4]],
      ["UNT", [22], ["SSDD1"]],
      ["UNZ", [1], [6002]]
    ]

    expect(result).to eq(expected)
  end

  it "parses a tradacoms file" do
    result = described_class.parse_file("#{FILES_DIR}/tradacoms.edi")
    expected = [
      ["STX", ["ANA", 1], [5000169000001, "DAVEY PLC"], [5060073022052, "Blackwood Limited"], [230102, "050903"],
       [3800], [], ["ORDHDR"]],
      ["MHD", [1], ["ORDHDR", 9]],
      ["TYP", ["0430"], ["NEW-ORDERS"]],
      ["SDT", [5060073022052, "005096"], ["BLACKWOOD LTD"]],
      ["CDT", [5000169000001, "WINDRAKER LTD"]],
      ["FIL", [3800], [1], [230102]],
      ["MTR", [14]],
      ["MHD", [4], ["ORDERS", 9]],
      ["CLO", [nil, 777, "BLACKWOOD D"]],
      ["ORD", ["B1102300", nil, 230102], [], ["N"]],
      ["DIN", [230103], [], [], ["PM"]],
      ["OLD", [1], [nil, 5000169475119], [5000169847442], [nil, "047836"], [12], [68], [], [], [],
       ["WR TStem Broccoli Spears"]],
      ["DNB", [1], [1], [], [nil, nil, 128, "KENYA/JOR/UK", 142, nil, 202, "060123"]],
      ["OLD", [2], [nil, 5000169073643], [5000169159491], [nil, "085482"], [16], [15], [], [], [],
       ["WR Asparagus", "IFCO 410"]],
      ["DNB", [2], [1], [], [108, 200, 128, "+++", 142, nil, 202, "080123"]],
      ["OLD", [3], [nil, 5000169073629], [5000169048726], [nil, "085486"], [12], [28], [], [], [],
       ["WR Fine Asparagus"]],
      ["DNB", [3], [1], [], [108, 225, 128, "THAI/peru", 142, nil, 202, "070123"]],
      ["OTR", [3]],
      ["MTR", [12]],
      ["MHD", [5], ["ORDTLR", 9]],
      ["OFT", [3]],
      ["MTR", [3]],
      ["END", [5]]
    ]

    expect(result).to eq(expected)
  end

  it "returns default edifact special characters" do
    result = described_class.una_special_characters
    expected = {
      component_data_element_seperator: ":",
      data_element_seperator: "+",
      decimal_notation: ".",
      escape_character: "?",
      segment_seperator: "'"
    }

    expect(result).to eq(expected)
  end

  it "returns altered edifact special characters" do
    result = described_class.una_special_characters('UNA!^,\ ~')
    expected = {
      component_data_element_seperator: "!",
      data_element_seperator: "^",
      decimal_notation: ",",
      escape_character: "\\",
      segment_seperator: "~"
    }

    expect(result).to eq(expected)
  end

  it "returns different altered edifact special characters" do
    result = described_class.una_special_characters("UNA012345")
    expected = {
      component_data_element_seperator: "0",
      data_element_seperator: "1",
      decimal_notation: "2",
      escape_character: "3",
      segment_seperator: "5"
    }

    expect(result).to eq(expected)
  end

  it "serializes a single line" do
    result = described_class.serialize(
      [
        ["UNB", ["IATB", 1], ["6XPPC"], ["LHPPC"], [940101, "0950"], [1]]
      ],
      with_service: false
    )
    expected = "UNB+IATB:1+6XPPC+LHPPC+940101:0950+1'"

    expect(result).to eq(expected)
  end

  it "serializes multiple lines" do
    result = described_class.serialize(
      [
        ["LIN", [1], [1], ["0764569104", "IB"]],
        ["QTY", [1, 25]]
      ],
      with_service: false
    )
    expected = "LIN+1+1+0764569104:IB'QTY+1:25'"

    expect(result).to eq(expected)
  end

  it "serializes multiple lines adding the service segment" do
    result = described_class.serialize(
      [
        ["LIN", [1], [1], ["0764569104", "IB"]],
        ["QTY", [1, 25]]
      ],
      with_service: true
    )
    expected = "UNA:+.? 'LIN+1+1+0764569104:IB'QTY+1:25'"

    expect(result).to eq(expected)
  end

  it "serializes with escaped characters" do
    result = described_class.serialize(
      [
        ["LIN", ["+:'?", 1], ["A Giant's tale:", "Does One + Two = Trouble??"], [156]]
      ],
      with_service: false
    )
    expected = "LIN+?+?:?'??:1+A Giant?'s tale?::Does One ?+ Two = Trouble????+156'"

    expect(result).to eq(expected)
  end

  it "serializes empty segments" do
    result = described_class.serialize(
      [
        ["QTY", [1]],
        [],
        ["QTY", [2]]
      ],
      with_service: false
    )
    expected = "QTY+1''QTY+2'"

    expect(result).to eq(expected)
  end

  it "serializes empty data elements" do
    result = described_class.serialize(
      [
        ["FTX", ["AFM"], [1], [], ["Java Server Programming"]]
      ],
      with_service: false
    )
    expected = "FTX+AFM+1++Java Server Programming'"

    expect(result).to eq(expected)
  end

  it "serializes empty data components" do
    result = described_class.serialize(
      [
        ["PDI", [], ["C", 3], ["Y", nil, 3], ["F", nil, 1], ["A"]]
      ],
      with_service: false
    )
    expected = "PDI++C:3+Y::3+F::1+A'"

    expect(result).to eq(expected)
  end

  it "serializes to a file" do
    result = described_class.serialize(
      [
        ["UNB", ["UNOA", 3], ["TESTPLACE", 1], ["DEP1", 1], [20051107, 1159], [6002]],
        ["UNH", ["SSDD1"], ["ORDERS", "D", "03B", "UN", "EAN008"]],
        ["BGM", [220], ["BKOD99"], [9]],
        ["DTM", [137, 20051107, 102]],
        ["NAD", ["BY"], [5412345000176, nil, 9]],
        ["NAD", ["SU"], [4012345000094, nil, 9]],
        ["LIN", [1], [1], ["0764569104", "IB"]],
        ["QTY", [1, 25]],
        ["FTX", ["AFM"], [1], [], ["XPath 2.0 Programmer's Reference"]],
        ["LIN", [2], [1], ["0764569090", "IB"]],
        ["QTY", [1, 25]],
        ["FTX", ["AFM"], [1], [], ["XSLT 2.0 Programmer's Reference"]],
        ["LIN", [3], [1], [1861004656, "IB"]],
        ["QTY", [1, 16]],
        ["FTX", ["AFM"], [1], [], ["Java Server Programming"]],
        ["LIN", [4], [1], ["0596006756", "IB"]],
        ["QTY", [1, 10]],
        ["FTX", ["AFM"], [1], [], ["Enterprise Service Bus"]],
        ["UNS", ["S"]],
        ["CNT", [2, 4]],
        ["UNT", [22], ["SSDD1"]],
        ["UNZ", [1], [6002]]
      ]
    )
    expected = File.read("#{FILES_DIR}/one_line.edi").chomp

    expect(result).to eq(expected)
  end
end
