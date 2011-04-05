require 'lib.rb'


connections = Hash.new(0)
im = Importer.new

im.each_transaction do |transaction|
  from = []
  to = []
  transaction.mutations.each { |m| (m.amount > 0 ? to : from) << m }
  from_total = from.inject(0) { |m,v| m + v.amount }
  to_total = to.inject(0) { |m,v| m + v.amount }
  
  if (from_total + to_total).abs > 0.05
    puts "To much difference between to and from: #{from_total + to_total}"
  end
  
  from.each do |from_mutation|
    to.each do |to_mutation|
      to_prop = to_mutation.amount.abs.to_f / (to_total.abs.to_f)
      amount = from_mutation.amount.abs * to_prop
      connections[[from_mutation.account, to_mutation.account]] += amount.abs
    end
  end

end

# Generates a dot graph showing flows of money between accounts. Can be limited to only flows
# between accounts that exceed X euros, specified by the first command line argument.
def to_dot(connections)
  puts "digraph G {"
  connections.map do |accounts, amount|
    if amount.abs > ARGV[0].to_i
      puts format("%s -> %s [weight=%i,label=\"€%i\"];", accounts[0].name.gsub(/[^a-zA-Z]/, ""), accounts[1].name.gsub(/[^a-zA-Z]/, ""), amount.abs.to_i, amount.abs.to_i)
    end
  end
  # Force a connection between Kostprijs Verkopen / Omzet
  puts "Kostprijsverkopen -> Omzet [weight=93054];"
  
  puts "}"
end

# Outputs how much money flows between two accounts
def stats(connections)
  puts "; Number of accounts: #{im.accounts.length}"
  
  conns = connections.map { |accounts, amount| ["#{accounts[0].full_name} => #{accounts[1].full_name}", amount]}
  puts conns.sort { |x,y| y[1] <=> x[1] }.map { |name,amount| format("%s => €%.2f", name, amount) }.join("\n")
end

# stats(connections)
to_dot(connections)
