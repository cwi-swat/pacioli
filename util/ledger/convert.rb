require 'lib.rb'

Importer.new.each_transaction { |trans| puts trans.to_ledger_format }