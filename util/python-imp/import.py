import sqlite3, os, csv, itertools
from collections import defaultdict
from decimal import Decimal
from fractions import Fraction

class Importer:
    def __init__(self, database, accounts, journals):
        try:
            os.remove(database)
        except:
            pass
        self.db = sqlite3.connect(database)
        self.accounts_file = accounts
        self.journals_file = journals
    
    def create_tables(self):
        c = self.db.cursor()

        c.execute("CREATE TABLE accounts (\
                 id            text,\
                 description   text,\
                 is_asset      text,    -- Boolean\n\
                 is_balance    text,    -- Boolean\n\
                 PRIMARY KEY (id)\
             )")
 
        c.execute("CREATE TABLE journals (\
                 id            text,\
                 description   text,\
                 PRIMARY KEY (id)\
             )")

        c.execute("CREATE TABLE journal_lines (\
                 id           integer,\
                 journal_id   text,\
                 account_id   text,\
                 amount       text NOT NULL,\
                 amount_mc    text NOT NULL,     -- Numeric amount rounded to millicents\n\
                 PRIMARY KEY (id)\
                 FOREIGN KEY (journal_id) REFERENCES journals(id)\
                 FOREIGN KEY (account_id) REFERENCES accounts(id)\
             )")

        c.execute("CREATE TABLE groups (\
                 id            integer,\
                 hash          text,\
                 description   text,\
                 total_debit   text,      -- pre-computed value\n\
                 accounts      text,      -- pre-computed value\n\
                 PRIMARY KEY (id)\
             )")
        c.execute("CREATE TABLE in_group (\
                 journal_id   text,\
                 group_id     integer,\
                 PRIMARY KEY (journal_id, group_id)\
                 FOREIGN KEY (journal_id) REFERENCES journals(id)\
                 FOREIGN KEY (group_id) REFERENCES groups(id)\
             )")

        c.close()
        
    def import_accounts(self):
        c = self.db.cursor()
        data = csv.reader(open(self.accounts_file, "r"))
        for row in data:
            c.execute("INSERT INTO accounts (id, description, is_asset, is_balance) VALUES(?, ?, ?, ?)", (row[0], row[1], False, False))
            print ",".join(row)
        c.close()

    def import_journals(self):
        c = self.db.cursor()
        data = csv.reader(open(self.journals_file, "r"))
        last_journal_id = None
        for row in data:
            journal_id = row[0]
            if last_journal_id != journal_id:
                c.execute("INSERT OR REPLACE INTO journals (id, description) VALUES(?, ?)", (row[0], row[1]))
            # "{DB81215D-FA1B-4D58-8E69-A2753DBA15F5}","Bestel.: 20300001",0,4743,"3000"
            amount = Decimal(row[2]) - Decimal(row[3])
            c.execute("INSERT OR REPLACE INTO journal_lines (journal_id, account_id, amount, amount_mc) VALUES (?, ?, ?, ?)", (row[0], row[4], str(amount), int(amount * Decimal(100000))))
        
        c.close()

    def create_indices(self):
        c = self.db.cursor()
        c.execute("CREATE INDEX indexj on journal_lines (journal_id)")
        c.execute("CREATE INDEX indexa on journal_lines (account_id)")
        c.execute("CREATE INDEX indexc on journal_lines (journal_id, account_id)")

        c.execute("CREATE INDEX indexe on in_group (journal_id)")
        c.execute("CREATE INDEX indexf on in_group (group_id)")
        c.close()
        
    def close(self):
        self.db.commit()
        self.db.close()

    def query_journal_lines(self, journal_id):
        accounts_sum = defaultdict(lambda: 0)
        accounts_description = {}
        c = self.db.cursor()
        for row in c.execute('SELECT accounts.id, journal_lines.amount, accounts.description\
            FROM journals\
            JOIN journal_lines ON journals.id = journal_lines.journal_id\
            JOIN accounts ON accounts.id = journal_lines.account_id\
            WHERE journals.id = ?', (journal_id,)):
            
            accounts_sum[row[0]] += Decimal(row[1])
            accounts_description[row[0]] = row[2]
        
        c.close()
        return [(account, sum, accounts_description[account]) for account, sum in accounts_sum.iteritems()]

    def journal_lines_debet(self, lines):
        return reduce(lambda a,x: a + x, (line[1] for line in lines if line[1] >= Decimal(0)), Decimal(0))
    
    def journal_lines_credit(self, lines):
        return abs(reduce(lambda a,x: a + x, (line[1] for line in lines if line[1] < Decimal(0)), Decimal(0)))
        
    def journal_lines_empty(self, lines):
        debit_amount = self.journal_lines_debet(lines)
        credit_amount = self.journal_lines_credit(lines)
        return debit_amount == Decimal(0) and credit_amount == Decimal(0)

    def journal_lines_complete(self, lines):
        return self.journal_lines_debet(lines) == self.journal_lines_credit(lines)
        
    def filter_journals(self):
        c = self.db.cursor()
        i = 0
        for row in c.execute("SELECT journals.id FROM journals"):
            i += 1
            journal_id = row[0]
            lines = self.query_journal_lines(journal_id)
            if (not self.journal_lines_complete(lines)) or self.journal_lines_empty(lines):
                print "Should delete journal: %s", journal_id
                d = self.db.cursor()
                d.execute("DELETE FROM journal_lines WHERE journal_id = ?", (journal_id,))
                d.execute("DELETE FROM journals WHERE id = ?", (journal_id,))
                d.close()
        print "Looked at %i journals" % i
        c.close()
    
    def generate_hash(self, lines):
        sorted_lines = sorted((x[0:2] for x in lines))

        amount = max(self.journal_lines_debet(lines), self.journal_lines_credit(lines))

        scaled = [[x[0], Fraction(str((x[1]/ amount).quantize(Decimal("0.01"))))] for x in sorted_lines]
        print scaled

        flattened = list(itertools.chain.from_iterable(scaled))
        return "(" + " ".join((str(x) for x in flattened)) + ")"

    def group_journals(self):
        hashes = {}
        c = self.db.cursor()
        for (journal_id, description) in c.execute("SELECT id, description FROM journals"):
            d = self.db.cursor()

            lines = sorted(self.query_journal_lines(journal_id))
            h = self.generate_hash(lines)
            print h
            if not h in hashes:
                # NOTE: total_debit is not the total debit, it's just the last debit
                d.execute("INSERT OR REPLACE INTO groups (hash, description, total_debit, accounts) VALUES (?, ?, ?, ?)",
                    (h, description, str(self.journal_lines_debet(lines)), ", ".join(sorted(map(lambda x: x[2], lines)))))
                hashes[h] = d.lastrowid
            
            d.execute("INSERT OR REPLACE INTO in_group (journal_id, group_id) VALUES (?, ?)", (journal_id, hashes[h]))
            d.close()

class FullImporter(Importer):
    
    def import_accounts(self):
        c = self.db.cursor()
        data = csv.reader(open(self.accounts_file, "r"))
        data.next()

        first = True
        for row in data:
            account_id = str(int(row[1])) # We get a different result with "row[1].strip()" with grouping ??
            description = row[2]
            is_balance = row[3] == "B"
            is_asset = row[4] == "D"
            values = (account_id, description, is_asset, is_balance)
            print values
            c.execute("INSERT INTO accounts (id, description, is_asset, is_balance) VALUES(?, ?, ?, ?)", values)
        c.close()

    
if __name__ == "__main__":
	import sys
	
	if len(sys.argv) != 4:
		print "usage: python generate_graph.py [database] [accounts_full.csv] [journals.csv]"
		print ""
		print "Imports data from the two csv files into the database"
		print sys.argv
		exit(1)

	importer = FullImporter(sys.argv[1], sys.argv[2], sys.argv[3])

	importer.create_tables()
	importer.import_accounts()
	importer.import_journals()
	importer.create_indices()
	importer.filter_journals()
	importer.group_journals()
	importer.close()
