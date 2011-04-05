require 'csv'

class Account
  attr_accessor :number, :name, :type
  
  def initialize(number, name, balance, debtor)
    @number = number.to_i
    @name = name
    if balance and debtor
      @type = "Assets"
    elsif balance and not debtor
      @type = "Liabilities"
    elsif not balance and debtor
      @type = "Expenses"
    else
      @type = "Income"
    end
  end
  
  def full_name
    return format("%s:%04i-%s", type, number, name.gsub(" ", "_"))
  end

end

class Mutation
  attr_accessor :date, :account, :amount, :description, :transaction_guid

  def initialize(date, account, amount, description, transaction_guid)
    @date = date
    @account = account
    @amount = amount
    @description = description
    @transaction_guid = transaction_guid
  end
  
  def to_ledger_format
    return "#{account.full_name}\t€#{format("%.2f", amount)}"
  end

end

class Transaction
  attr_accessor :description, :date, :mutations
  
  def initialize(guid, date, description)
    @guid = guid
    @description = description
    @date = date
    @mutations = []
  end

  def matches_mutation?(mutation)
    @guid == mutation.transaction_guid
  end

  def to_ledger_format
    "#{date} #{description} [#{@guid}]\n\t" + @mutations.map { |m| m.to_ledger_format }.join("\n\t") + "\n"
  end

  def add_mutation(mutation)
    @mutations << mutation
  end
end

class Importer

  attr_reader :accounts

  def initialize(accounts_file=nil, transactions_file=nil)
    @accounts = {}
    @transactions_file = transactions_file || "../exact-data/journals_full.csv"
    
    read_accounts(accounts_file || "../exact-data/accounts_full.csv")
  end

  def read_accounts(accounts_file)
    accounts = CSV.read(accounts_file)
    # Remove first line, which are just headers
    accounts.shift

    accounts.each do |line|
      number = line[1]
      @accounts[number.to_i] = Account.new(number, line[2], line[3] == "B", line[4] == "D")
    end
  end

  def each_mutation
    mutations = CSV.read(@transactions_file)
    # Drop the first (header) line
    mutations.shift

    mutations.each do |line|
      date = line[0]
      account = @accounts[line[1].to_i]
      description = (line[5] || "").strip
      amount = line[6].to_f
      transaction_guid = line[8].strip

      mutation = Mutation.new(date, account, amount, description, transaction_guid)
      yield mutation
    end
  end
  
  # Call with a block, which is called for every transaction in the list.
  # Assumes all the mutations for a single transaction are grouped
  def each_transaction
    last_transaction = nil

    each_mutation do |mutation|  
      unless last_transaction and last_transaction.matches_mutation? mutation
        yield last_transaction if last_transaction
        last_transaction = Transaction.new(mutation.transaction_guid, mutation.date, mutation.description)
      end
      last_transaction.add_mutation(mutation)
    end
  end

end