
require 'active_support/all'

# 定数を定義
months = (1..36).to_a  # 3年間
num_months = months.size
units_sold_base = 100  # 月ごとの販売ユニット数の基準値
unit_price_base = 1000  # ユニットごとの価格の基準値
unit_cost_base = 400  # ユニットごとのコストの基準値
employees_base = 10  # 従業員数の基準値
employee_salary_per_person = 1000  # 従業員ごとの給料（月）
rent_base = 2000  # レンタル費用の基準値（月）
utilities_base = 1000  # 公共料金の基準値（月）
advertising_costs_base = 2000  # 広告費の基準値（月）
