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

accounts = dict()

def load_accounts():
    rows = c.execute("SELECT CAST(id AS NUMERIC), description, CAST(is_asset AS BOOLEAN) FROM accounts")
    for row in rows:
        (id, description, is_asset) = row
        # print row
        accounts[id] = { "description": description, "asset": is_asset == 1, "used": False }

def print_transactions():
    limit = 10
    if len(sys.argv) >= 3 and len(sys.argv[2]) > 0:
        limit = sys.argv[2]

    rows = c.execute("SELECT id, hash, description, CAST(total_debit AS FLOAT) from groups ORDER BY CAST(total_debit AS FLOAT) DESC LIMIT ?", (limit, ))

    for row in rows:
        h = row[1][1:-1].split(" ")
        for i in range(0, len(h), 2):
            account_id = int(h[i])
            account = accounts[account_id]
            account["used"] = True
            print "Trans%s [shape=box, label=\"%s\"];" % (row[0], row[2])
            if h[i+1].startswith("-") != account["asset"]:
                print "Trans%s -> Acc%04i;" % (row[0], account_id)
            else:
                print "Acc%04i -> Trans%s;" % (account_id, row[0])
    return accounts

def print_accounts():
    for id in accounts:
        account = accounts[id]        
        if account["used"]:
            label = account["description"]
            if not account["asset"]:
                label += "[-]"
            print "Acc%04i [label=\"%s\"]" % (id, label)
        
print "digraph G {"
print "  edge [len=2]"
load_accounts()
print_transactions()
print_accounts()
print "Finish [shape=box, label=\"Winst\"];"
print "Acc7000 -> Finish;"
print "Finish -> Acc8000;"
print "}"

c.close()
db.close()
