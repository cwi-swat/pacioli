import sqlite3, os, csv, itertools, sys
from collections import defaultdict
from decimal import Decimal
from fractions import Fraction

if len(sys.argv) < 2:
	print "usage: python generate_graph.py database [num_transactions]"
	print
	print "Reads in the top num_transactions from the database and outputs a"
	print "description of those transactions in the dot language"
	exit(1)


db = sqlite3.connect(sys.argv[1])
c = db.cursor()

def print_transactions():
    limit = 10
    if len(sys.argv) >= 3 and len(sys.argv[2]) > 0:
        limit = sys.argv[2]

    rows = c.execute("SELECT id, hash, description, CAST(total_debit AS FLOAT) from groups ORDER BY CAST(total_debit AS FLOAT) DESC LIMIT ?", (limit, ))
    accounts = set();
    for row in rows:
        h = row[1][1:-1].split(" ")
        for i in range(0, len(h), 2):
            account = int(h[i])
            accounts.add(account)
            print "Trans%s [shape=box, label=\"%s\"]" % (row[0], row[2])
            if not h[i+1].startswith("-"):
                print "Trans%s -> Acc%04i" % (row[0], account)
            else:
                print "Acc%04i -> Trans%s" % (account, row[0])
    return accounts

def print_accounts(accounts):
    rows = c.execute("SELECT CAST(id AS NUMERIC), description FROM accounts")
    for (id, description) in rows:
        if id in accounts:
            print "Acc%04i [label=\"%s\"]" % (id, description)
        
print "digraph G {"
print "  edge [len=2;]"
accounts = print_transactions()
print_accounts(accounts)
print "Finish [shape=box, label=\"Winst\"]"
print "Acc7000 -> Finish"
print "Finish -> Acc8000"
print "}"

c.close()
db.close()
