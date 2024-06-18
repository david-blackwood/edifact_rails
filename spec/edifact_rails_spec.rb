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
    result = described_class.parse("UNB'LIN+1+1+0764569104:IB'QTY+1:25'")
    expected = [
      ["UNB"],
      ["LIN", [1], [1], ["0764569104", "IB"]],
      ["QTY", [1, 25]]
    ]

    expect(result).to eq(expected)
  end

  it "parses escaped characters" do
    result = described_class.parse("UNB'LIN+?+?:?'??:1+A Giant?'s tale?::Does One ?+ Two = Trouble????+156")
    expected = [
      ["UNB"],
      ["LIN", ["+:'?", 1], ["A Giant's tale:", "Does One + Two = Trouble??"], [156]]
    ]
    expect(result).to eq(expected)
  end

  it "parses empty segments" do
    result = described_class.parse("UNB'QTY+1''QTY+2")
    expected = [
      ["UNB"],
      ["QTY", [1]],
      [],
      ["QTY", [2]]
    ]

    expect(result).to eq(expected)
  end

  it "parses empty data elements" do
    result = described_class.parse("UNB'FTX+AFM+1++Java Server Programming'")
    expected = [
      ["UNB"],
      ["FTX", ["AFM"], [1], [], ["Java Server Programming"]]
    ]

    expect(result).to eq(expected)
  end

  it "parses empty data components" do
    result = described_class.parse("UNB'PDI++C:3+Y::3+F::1+A'")
    expected = [
      ["UNB"],
      ["PDI", [], ["C", 3], ["Y", nil, 3], ["F", nil, 1], ["A"]]
    ]

    expect(result).to eq(expected)
  end

  it "parses lines with excess spaces and carraige returns between the segments" do
    result = described_class.parse("\n   UNB'\r\n  PDI++C:3+Y::3+F::1+A  '\r\n")
    expected = [
      ["UNB"],
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

  it "parses an ansix12 file" do
    result = described_class.parse_file("#{FILES_DIR}/ansix12.edi")
    expected = [
      ["ISA", ["00"], [nil], ["00"], [nil], ["01"], ["SENDER"], ["01"], ["RECEIVER"], [231014], [1200], ["U"], ["00401"], ["000000001"], [1], ["P"], []],
      ["GS", ["SS"], ["APP SENDER"], ["APP RECEIVER"], [20231014], [1200], ["0001"], ["X"], ["004010"]],
      ["ST", [862], ["0001"]],
      ["BSS", ["05"], [12345], [20230414], ["DL"], [20231014], [20231203], [], [], [], ["ORDER1"], ["A"]],
      ["N1", ["MI"], ["SEEBURGER AG"], ["ZZ"], ["00000085"]],
      ["N3", ["EDISONSTRASSE 1"]],
      ["N4", ["BRETTEN"], [], [75015], ["DE"]],
      ["N1", ["SU"], ["SUPLIER NAME"], ["ZZ"], [11222333]],
      ["N3", ["203 STREET NAME"]],
      ["N4", ["ATLANTA"], ["GA"], [30309], ["US"]],
      ["LIN", [], ["BP"], ["MATERIAL1"], ["EC"], ["ENGINEERING1"], ["DR"], ["001"]],
      ["UIT", ["EA"]],
      ["PER", ["SC"], ["SEEBURGER INFO"], ["TE"], ["+49(7525)0"]],
      ["FST", [13], ["C"], ["D"], [20231029], [], [], [], ["DO"], ["12345-1"]],
      ["FST", [77], ["C"], ["D"], [20231119], [], [], [], ["DO"], ["12345-2"]],
      ["FST", [68], ["C"], ["D"], [20231203], [], [], [], ["DO"], ["12345-3"]],
      ["SHP", ["01"], [927], ["011"], [20231014]],
      ["REF", ["SI"], ["Q5880"]],
      ["SHP", ["02"], [8557], ["011"], [20231014], [], [20231203]],
      ["CTT", [1], [5]],
      ["SE", [19], ["0001"]],
      ["GE", [1], ["0001"]],
      ["IEA", [1], ["000000001"]]
    ]

    expect(result).to eq(expected)
  end

  it "parses an ansix12 file with newlines as segment seperators" do
    result = described_class.parse_file("#{FILES_DIR}/ansix12_newlines.edi")
    expected = [
      ["ISA", ["00"], [nil], ["00"], [nil], ["01"], ["SENDER"], ["01"], ["RECEIVER"], [231014], [1200], ["U"], ["00401"], ["000000001"], [1], ["P"], []],
      ["GS", ["SS"], ["APP SENDER"], ["APP RECEIVER"], [20231014], [1200], ["0001"], ["X"], ["004010"]],
      ["ST", [862], ["0001"]],
      ["BSS", ["05"], [12345], [20230414], ["DL"], [20231014], [20231203], [], [], [], ["ORDER1"], ["A"]],
      ["N1", ["MI"], ["SEEBURGER AG"], ["ZZ"], ["00000085"]],
      ["N3", ["EDISONSTRASSE 1"]],
      ["N4", ["BRETTEN"], [], [75015], ["DE"]],
      ["N1", ["SU"], ["SUPLIER NAME"], ["ZZ"], [11222333]],
      ["N3", ["203 STREET NAME"]],
      ["N4", ["ATLANTA"], ["GA"], [30309], ["US"]],
      ["LIN", [], ["BP"], ["MATERIAL1"], ["EC"], ["ENGINEERING1"], ["DR"], ["001"]],
      ["UIT", ["EA"]],
      ["PER", ["SC"], ["SEEBURGER INFO"], ["TE"], ["+49(7525)0"]],
      ["FST", [13], ["C"], ["D"], [20231029], [], [], [], ["DO"], ["12345-1"]],
      ["FST", [77], ["C"], ["D"], [20231119], [], [], [], ["DO"], ["12345-2"]],
      ["FST", [68], ["C"], ["D"], [20231203], [], [], [], ["DO"], ["12345-3"]],
      ["SHP", ["01"], [927], ["011"], [20231014]],
      ["REF", ["SI"], ["Q5880"]],
      ["SHP", ["02"], [8557], ["011"], [20231014], [], [20231203]],
      ["CTT", [1], [5]],
      ["SE", [19], ["0001"]],
      ["GE", [1], ["0001"]],
      ["IEA", [1], ["000000001"]]
    ]

    expect(result).to eq(expected)
  end

  it "returns default edifact special characters" do
    result = described_class.special_characters
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
    result = described_class.special_characters('UNA!^,\ ~')
    expected = {
      component_data_element_seperator: "!",
      data_element_seperator: "^",
      decimal_notation: ",",
      escape_character: "\\",
      segment_seperator: "~"
    }

    expect(result).to eq(expected)

    result = described_class.special_characters("UNA012345")
    expected = {
      component_data_element_seperator: "0",
      data_element_seperator: "1",
      decimal_notation: "2",
      escape_character: "3",
      segment_seperator: "5"
    }

    expect(result).to eq(expected)
  end

  it "returns ansix12 special characters" do
    result = described_class.special_characters('ISA*00*          *00*          *01*SENDER         *01*RECEIVER       *231014*1200*U*00401*000000001*1*P*>~')
    expected = {
      component_data_element_seperator: ">",
      data_element_seperator: "*",
      segment_seperator: "~"
    }

    expect(result).to eq(expected)

    result = described_class.special_characters("ISA*00*          *00*          *01*SENDER         *01*RECEIVER       *231014*1200*U*00401*000000001*1*P*:\nST*862*0001~\n")
    expected = {
      component_data_element_seperator: ":",
      data_element_seperator: "*",
      segment_seperator: "\n"
    }

    expect(result).to eq(expected)
  end

  it "raises an error when the format is not recognized" do
    expect { described_class.parse("Hello there") }.to raise_error(EdifactRails::UnrecognizedFormat)
    expect { described_class.parse("UNG") }.to raise_error(EdifactRails::UnrecognizedFormat)
    expect { described_class.special_characters("1234567890") }.to raise_error(EdifactRails::UnrecognizedFormat)
    expect { described_class.special_characters("!UNA") }.to raise_error(EdifactRails::UnrecognizedFormat)
  end
end
