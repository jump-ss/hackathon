require 'securerandom'

class Product
  attr_accessor :name, :price, :category

  def initialize(name, price, category)
    @name = name
    @price = price
    @category = category
  end
end

class Client
  attr_accessor :name, :client_type

  def initialize(name, client_type)
    @name = name
    @client_type = client_type
  end
end

class Employee
  attr_accessor :name, :employee_type, :salary, :expenses

  def initialize(name, employee_type, salary, expenses)
    @name = name
    @employee_type = employee_type
    @salary = salary
    @expenses = expenses
  end
end

class Invoice
  attr_accessor :client, :product, :quantity, :total_price

  def initialize(client, product, quantity)
    @client = client
    @product = product
    @quantity = quantity
    @total_price = product.price * quantity
  end
end

class BusinessSimulation
  attr_accessor :products, :clients, :employees, :invoices, :monthly_data, :yearly_data, :cash_balance

  def initialize(products, clients, employees, initial_cash_balance)
    @products = products
    @clients = clients
    @employees = employees
    @invoices = []
    @monthly_data = []
    @yearly_data = {
      'sales' => 0,
      'accounts_receivable' => 0,
      'cost_of_goods_sold' => 0,
      'accounts_payable' => 0,
      'notes_payable' => 0,
      'gross_profit' => 0,
      'salaries' => 0,
      'expenses' => 0,
      'operating_profit' => 0,
      'non_operating_income' => 0,
      'non_operating_expenses' => 0,
      'ordinary_profit' => 0,
      'extraordinary_income' => 0,
      'extraordinary_losses' => 0,
      'income_before_income_taxes' => 0,
      'income_taxes' => 0,
      'net_income' => 0
    }
    @cash_balance = initial_cash_balance
  end

  def generate_invoices
    @products.each do |product|
      @clients.each do |client|
        num_sales = SecureRandom.random_number(10) + 1
        num_sales = SecureRandom.random_number(90) + 10 if client.client_type == 'corporate'
        @invoices << Invoice.new(client, product, num_sales)
      end
    end
  end

  def calculate_monthly_salaries
    @employees.map(&:salary).reduce(:+)
  end

  def calculate_monthly_expenses
    @employees.map(&:expenses).reduce(:+)
  end

  def calculate_monthly_data
    # Reset monthly data
    @monthly_data = []

    @invoices.each do |invoice|
      total_sales = invoice.total_price
      # If the product price is less than or equal to 100000, it is paid by credit card or cash
      @monthly_data << if invoice.product.price <= 100_000
                         { 'product_sales' => total_sales, 'service_sales' => 0, 'product_receivables' => 0,
                           'service_receivables' => 0 }
                       # If the product price is more than 100000, it is paid by notes
                       else
                         { 'product_sales' => 0, 'service_sales' => total_sales, 'product_receivables' => 0,
                           'service_receivables' => SecureRandom.random_number(total_sales) }
                       end
    end
    @monthly_data << { 'salaries' => calculate_monthly_salaries, 'expenses' => calculate_monthly_expenses }
  end

  def calculate_yearly_data
    # Reset yearly data
    @yearly_data = @yearly_data.transform_values { |_| 0 }

    # Add up monthly data
    @monthly_data.each do |data|
      @yearly_data.keys.each do |key|
        @yearly_data[key] += data[key].to_i
      end
    end

    # If the business is running at a loss, try to recover
    return unless @yearly_data['net_income'] < 0

    # Try to recover by increasing revenue
    @yearly_data['revenue'] += @yearly_data['net_income'].abs
    @yearly_data['net_income'] = 0
  end

  def purchase_products(product, quantity)
    cost = product.price * quantity
    if @cash_balance >= cost
      @cash_balance -= cost
      @yearly_data['cost_of_goods_sold'] += cost
    else
      borrowed_amount = cost - @cash_balance
      @cash_balance = 0
      @yearly_data['notes_payable'] += borrowed_amount
      @yearly_data['cost_of_goods_sold'] += cost
    end
  end
end
