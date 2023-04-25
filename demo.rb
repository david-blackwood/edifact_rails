require_relative 'lib/edifact_rails'

puts EdifactRails::parse("UNB+IATB:1+6XPPC+LHPPC+940101:0950+1'")

puts '-----'

puts EdifactRails::parse_file(open('./test/files/seperate_lines.edi'))