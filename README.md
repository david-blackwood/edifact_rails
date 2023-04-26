# EdifactRails

This gem allows you to parse EDIFACT input - strings or files - and convert them into a ruby array structure for additional validation and processing.

It does not handle validation itself.

This gem is heavily influenced by and attempts to output the same results as [edifact_parser](https://github.com/pvdvreede/edifact_parser), credits to [pvdvreede](https://github.com/pvdvreede)

## Requirements

This gem has been tested on the following ruby versions:
* 2.7.8
* 3.0.6
* 3.1.2
* 3.2.2

## Getting started 

```
gem install edifact_rails
```

Or, in your `Gemfile`:

```
gem 'edifact_rails'
```

## Usage

```ruby
require 'edifact_rails'
```

Then, you can pass either the path to your EDIFACT file, or a document as a string:

```ruby
ruby_array = EdifactRails.parse_file("your/file/path")
```

```ruby
ruby_array = EdifactRails.parse("LIN+1+1+0764569104:IB'QTY+1:25'")
```

## Output

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
