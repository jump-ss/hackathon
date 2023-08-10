
# Compute the financials for each month
accounts_receivable = 0  # 売掛金
accounts_payable = 0  # 買掛金
cash = 0  # 現金
months.each do |month|
  units_sold = (units_sold_base * rand(0.9..1.1) * procurement_adjustment).round
  unit_cost = unit_cost_base * rand(0.9..1.1) * costs_adjustment
  procurement_costs = units_sold * unit_cost
  unit_price = unit_price_base * (1 + 0.05 * (unit_cost / unit_cost_base - 1))  # 単位コストが上昇した場合、単位価格を上昇させます
  revenue = units_sold * unit_price
  employees = (employees_base * rand(0.8..1.2)).round
  employee_salary = employees * employee_salary_per_person * expenses_adjustment
  rent = rent_base * rand(0.9..1.1) * expenses_adjustment
  utilities = utilities_base * rand(0.9..1.1) * expenses_adjustment
  overhead_costs = rent + utilities
  advertising_costs = advertising_costs_base * rand(0.8..1.2) * expenses_adjustment
  units_sold = (units_sold * (1 + 0.05 * (advertising_costs / advertising_costs_base - 1))).round  # 広告費が増加した場合、販売ユニット数を増加させます
  profit = revenue - procurement_costs - employee_salary - overhead_costs - advertising_costs

  # 売掛金と買掛金を計算
  accounts_receivable += revenue
  accounts_payable += procurement_costs + employee_salary + overhead_costs + advertising_costs

  # 現金を計算（売掛金 - 買掛金）
  cash = accounts_receivable - accounts_payable

  # 各販売ユニットごとに取引詳細を生成
  transaction_ids = []
  (1..units_sold).each do
    transaction = {
      id: transaction_counter,
      month: month,
      customer: customers.sample,
      product: products.sample,
      transaction_date: Date.new(Date.current.year, month, rand(1..28)),
      unit_cost: unit_cost,
      unit_price: unit_price
    }
    transactions << transaction
    transaction_ids << transaction_counter
    transaction_counter += 1
  end

  financials << {
    month: month,
    units_sold: units_sold,
    revenue: revenue,
    procurement_costs: procurement_costs,
    employees: employees,
    employee_salary: employee_salary,
    rent: rent,
    utilities: utilities,
    overhead_costs: overhead_costs,
    advertising_costs: advertising_costs,
    profit: profit,
    accounts_receivable: accounts_receivable,
    accounts_payable: accounts_payable,
    cash: cash,
    transaction_ids: transaction_ids
  }
end
