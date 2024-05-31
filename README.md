# EdifactRails

This gem parses EDIFACT or TRADACOMS input, and converts it into a ruby array structure for whatever further processing or validation you desire.

It does not handle validation itself.

This gem is heavily inspired by and attempts to output similar results as [edifact_parser](https://github.com/pvdvreede/edifact_parser), credits to [pvdvreede](https://github.com/pvdvreede)

## Requirements

This gem requires Ruby 3.0+.

This gem has been tested on the following ruby versions:
* 3.0.6
* 3.1.2
* 3.2.2

## Getting started

In your `Gemfile`:

```ruby
gem 'edifact_rails', '~> 1.2'
```

Otherwise:

```
gem install edifact_rails
```

## Usage

If you don't have the gem in your `Gemfile`, you will need to:

```ruby
require 'edifact_rails'
```

You can pass either the path to your EDIFACT (or TRADACOMS) file, or a document (or snippet) as a string:

```ruby
ruby_array = EdifactRails.parse_file("your/file/path")
```

```ruby
ruby_array = EdifactRails.parse("LIN+1+1+0764569104:IB'QTY+1:25'")
```

You can pull just the special characters from the UNA segment (or the defaults if no UNA segment is present):
```ruby
una_special_characters = EdifactRails.una_special_characters(your_string_input)
# una_special_characters =>
{
  component_data_element_seperator: ":",
  data_element_seperator: "+",
  escape_character: "?",
  segment_seperator: "'"
}
```

## Output

### EDIFACT

This example EDIFACT file:

```
UNA:+.? '
UNB+UNOA:3+TESTPLACE:1+DEP1:1+20051107:1159+6002'
UNH+SSDD1+ORDERS:D:03B:UN:EAN008'
BGM+220+BKOD99+9'
DTM+137:20051107:102'
NAD+BY+5412345000176::9'
NAD+SU+4012345000094::9'
LIN+1+1+0764569104:IB'
QTY+1:25'
FTX+AFM+1++XPath 2.0 Programmer?'s Reference'
LIN+2+1+0764569090:IB'
QTY+1:25'
FTX+AFM+1++XSLT 2.0 Programmer?'s Reference'
LIN+3+1+1861004656:IB'
QTY+1:16'
FTX+AFM+1++Java Server Programming'
LIN+4+1+0596006756:IB'
QTY+1:10'
FTX+AFM+1++Enterprise Service Bus'
UNS+S'
CNT+2:4'
UNT+22+SSDD1'
UNZ+1+6002'
```

Will be returned as:

```ruby
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
```

### TRADACOMS

This TRADACOMS file:

```
STX=ANA:1+5000169000001:DAVEY PLC+5060073022052:Blackwood Limited+230102:050903+3800++ORDHDR'
MHD=1+ORDHDR:9'
TYP=0430+NEW-ORDERS'
SDT=5060073022052:005096+BLACKWOOD LTD'
CDT=5000169000001:WINDRAKER LTD'
FIL=3800+1+230102'
MTR=14'
MHD=4+ORDERS:9'
CLO=:777:BLACKWOOD D'
ORD=B1102300::230102++N'
DIN=230103+++PM'
OLD=1+:5000169475119+5000169847442+:047836+12+68++++WR TStem Broccoli Spears'
DNB=1+1++::128:KENYA/JOR/UK:142::202:060123'
OLD=2+:5000169073643+5000169159491+:085482+16+15++++WR Asparagus:IFCO 410'
DNB=2+1++108:200:128:?+?+?+:142::202:080123'
OLD=3+:5000169073629+5000169048726+:085486+12+28++++WR Fine Asparagus'
DNB=3+1++108:225:128:THAI/peru:142::202:070123'
OTR=3'
MTR=12'
MHD=5+ORDTLR:9'
OFT=3'
MTR=3'
END=5
```

Will be returned as:

```ruby
[
  ['STX', ['ANA', 1], [5000169000001, 'DAVEY PLC'], [5060073022052, 'Blackwood Limited'], [230102, '050903'], [3800], [], ['ORDHDR']],
  ['MHD', [1], ['ORDHDR', 9]],
  ['TYP', ['0430'], ['NEW-ORDERS']],
  ['SDT', [5060073022052, '005096'], ['BLACKWOOD LTD']],
  ['CDT', [5000169000001, 'WINDRAKER LTD']],
  ['FIL', [3800], [1], [230102]],
  ['MTR', [14]],
  ['MHD', [4], ['ORDERS', 9]],
  ['CLO', [nil, 777, 'BLACKWOOD D']],
  ['ORD', ['B1102300', nil, 230102], [], ['N']],
  ['DIN', [230103], [], [], ['PM']],
  ['OLD', [1], [nil, 5000169475119], [5000169847442], [nil, '047836'], [12], [68], [], [], [], ['WR TStem Broccoli Spears']],
  ['DNB', [1], [1], [], [nil, nil, 128, 'KENYA/JOR/UK', 142, nil, 202, '060123']],
  ['OLD', [2], [nil, 5000169073643], [5000169159491], [nil, '085482'], [16], [15], [], [], [], ['WR Asparagus', 'IFCO 410']],
  ['DNB', [2], [1], [], [108, 200, 128, '+++', 142, nil, 202, '080123']],
  ['OLD', [3], [nil, 5000169073629], [5000169048726], [nil, '085486'], [12], [28], [], [], [], ['WR Fine Asparagus']],
  ['DNB', [3], [1], [], [108, 225, 128, 'THAI/peru', 142, nil, 202, '070123']],
  ['OTR', [3]],
  ['MTR', [12]],
  ['MHD', [5], ['ORDTLR', 9]],
  ['OFT', [3]],
  ['MTR', [3]],
  ['END', [5]]
]
```