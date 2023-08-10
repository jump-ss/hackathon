require_relative 'business_simulation'

# Define the products for the furniture business
products = [
  Product.new('Chair', 5000, 'low_price'),
  Product.new('Table', 10_000, 'low_price'),
  Product.new('Sofa', 15_000, 'low_price'),
  Product.new('Bed', 20_000, 'low_price'),
  Product.new('Wardrobe', 30_000, 'low_price'),
  Product.new('Dining set', 500_000, 'high_price'),
  Product.new('Office desk', 800_000, 'high_price'),
  Product.new('Bookcase', 600_000, 'high_price'),
  Product.new('TV stand', 150_000, 'high_price'),
  Product.new('Drawer chest', 250_000, 'high_price')
]

# Define the clients for the furniture business
clients = [
  Client.new('Individual 1', 'individual'),
  Client.new('Individual 2', 'individual'),
  Client.new('Individual 3', 'individual'),
  Client.new('Individual 4', 'individual'),
  Client.new('Individual 5', 'individual'),
  Client.new('Company A', 'corporate'),
  Client.new('Company B', 'corporate'),
  Client.new('Company C', 'corporate'),
  Client.new('Company D', 'corporate'),
  Client.new('Company E', 'corporate')
]

# Define the employees for the furniture business
employees = [
  Employee.new('Alice', 'full_time', 300_000, 20_000),
  Employee.new('Bob', 'part_time', 150_000, 10_000)
]

# Let's say the business starts with 1 million yen in cash
initial_cash_balance = 1_000_000

# Create a business simulation
simulation = BusinessSimulation.new(products, clients, employees, initial_cash_balance)

# Run the simulation for one year
12.times do
  # Generate invoices for this month
  simulation.generate_invoices
  # Calculate monthly data
  simulation.calculate_monthly_data
  # Purchase products for this month
  simulation.products.each do |product|
    simulation.purchase_products(product, rand(1..10))
  end
end

# Calculate yearly data
simulation.calculate_yearly_data

# Output the invoices and the yearly data
puts 'Invoices:'
simulation.invoices.each_with_index do |invoice, index|
  puts "Invoice #{index}: #{invoice.product.name}, #{invoice.quantity}, #{invoice.client.name}, #{invoice.total_price}"
end

puts 'Yearly data:'
simulation.yearly_data.each do |key, value|
  puts "#{key}: #{value}"
end
