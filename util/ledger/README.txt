This directory contains a quick 'n dirty ruby
implementation that allows you to read the data from the
CSV files extracted out of Exact.

It can be used to generate a dot graph showing money
flows between accounts (but not groupd by transaction),
and some basic stats about the data. The implementation
is in a rough library form, so it could be reusable.

The 'convert.rb' file converts the extracted data to
Ledger format (see
https://github.com/jwiegley/ledger/wiki/). This can be
used to validate the extraction, as Ledger should give
roughly the same totals as Exact reports within the app.
The 'ledger.txt' is the latest output of this conversion
script.

These scripts don't have any dependencies other than
ruby.