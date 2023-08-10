# docker-compose run web rails c
# require './lib/startup_game' で起動
require 'highline'
require 'rest-client'
require 'logger'

cli = HighLine.new
users = {
  'user1' => 'password1',
  'user2' => 'password2'
}

def login(users, cli)
  username = cli.ask('Enter your username:  ') { |q| q.default = 'user1' }
  password = cli.ask('Enter your password:  ') do |q|
    q.default = 'password1'
    q.echo = '*'
  end

  if users[username] == password
    puts 'Login successful!'
    true
  else
    puts 'Login failed. Please try again.'
    false
  end
end

def run_mode(mode, cli)
  case mode
  when 'Cash Flow Mode'
    # Run Cash Flow Mode
    puts 'Running Cash Flow Mode...'
    # TODO: Implement Cash Flow Mode
  when 'Investment Mode'
    # Run Investment Mode
    puts 'Running Investment Mode...'
    # TODO: Implement Investment Mode
  when 'Simulation Mode'
    # Run Simulation Mode
    puts 'Running Simulation Mode...'
    simulations = %w[自作キーボードを作成して販売する事業 ポケモンカードの転売する事業]
    simulation = cli.choose do |menu|
      menu.prompt = '事業内容を選択してください'
      menu.choices(*simulations)
    end
    run_simulation(simulation)
  end
end

def run_simulation(simulation)
  puts 'シミュレーションを実行します'
  puts get_deal_oneday(simulation)
end

def start_game(users, cli)
  puts 'Welcome to the Startup Simulation Game!'
  login_successful = false

  login_successful = login(users, cli) until login_successful

  modes = ['Cash Flow Mode', 'Investment Mode', 'Simulation Mode']
  mode = cli.choose do |menu|
    menu.prompt = 'Please choose your mode:  '
    menu.choices(*modes)
  end

  run_mode(mode, cli)
end

def get_deal_oneday(input_text)
  return unless input_text

  api_key = ENV['OPENAI_API_KEY']
  api_endpoint = 'https://api.openai.com/v1/chat/completions'

  #  prompt = '入力に対してランダムな明細（wallet_txn）テストデータを生成してください。出力形式：["wallet_txn":{"id":1,"company_id":1,"date":"2019-12-17","amount":5000,"due_amount":0,"balance":10000,"entry_side":"income","walletable_type":"bank_account","walletable_id":1,"description":"振込カ）ABC","status":0,"rule_matched":true}]　入力:' + "#{input_text.encode(Encoding::UTF_8)}"
  prompt = '事業内容から取引を推測して発生しうるテストデータを一日分だけ作成する。事業内容:' + "#{input_text.encode(Encoding::UTF_8)}"

  body = {
    "model": 'gpt-3.5-turbo-0613',
    "temperature": 0.5,
    "messages": [{ "role": 'user', "content": prompt }],
    "functions": [
      {
        "name": 'send_deal_result',
        "description": '事業内容から発生しうる取引を推測し、取引情報を生成する',
        "parameters": {
          "type": 'object',
          "properties": {
            "comment": {
              "type": 'string',
              "description": '発生した取引の具体的な内容を決めて、適当に生成する'
            },
            "deals": {
              "type": 'array',
              "description": ' 取引情報をランダムで1から3つ作成する',
              "items": {
                "type": 'object',
                "description": '取引情報を推測してランダムに提示する',
                "properties": {
                  "issue_date": {
                    "type": 'string',
                    "description": ' 発生日'
                  },
                  "due_date ": {
                    "type": 'string',
                    "description": ' 支払期日'
                  },
                  "amount": {
                    "type": 'string',
                    "description": ' 金額'
                  },
                  "due_amount ": {
                    "type": 'string',
                    "description": '支払残額'
                  },
                  "type": {
                    "type": 'string',
                    "description": '入金／出金 (入金: income, 出金: expense)'
                  },
                  "details ": {
                    "type": 'array',
                    "description": ' 取引の明細行、ランダムで1から3行作成する',
                    "items": {
                      "type": 'object',
                      "description": ' 取引の明細行',
                      "properties": {
                        "tax": {
                          "type": 'string',
                          "description": ' 税区分名（日本語表示用）'
                        },
                        "account_item": {
                          "type": 'string',
                          "description": ' 勘定科目名'
                        },
                        "amount": {
                          "type": 'string',
                          "description": ' 取引金額（税込で指定してください）マイナスの値を指定した場合、控除・マイナス行として登録されます。上記以外の値を指定した場合、通常行として登録されます。'
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          "required": %w[comment deals]
        }
      }
    ],
    "function_call": { "name": 'send_deal_result' }
  }
  headers = {
    "Content-Type": 'application/json',
    "Authorization": "Bearer #{api_key}"
  }

  begin
    response = RestClient.post(api_endpoint, body.to_json, headers)
  rescue StandardError => e
    logger.error JSON.parse(response)
    # 何らかのエラーが発生した場合はログの書き込みと、
    # エラー通知サービスへの通知を行う
    # logger.error e
    # logger.error e.backtrace.join("\n")

    raise 'Charge failed. ErrCode: 500 / ErrMessage: '
  end

  response_body = JSON.parse(response.body)['choices'][0]['message']

  JSON.parse(response_body['function_call']['arguments'])
end

start_game(users, cli)
