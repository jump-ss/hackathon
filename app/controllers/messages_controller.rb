require 'rest-client'

class MessagesController < ApiController
  skip_before_action :verify_authenticity_token
  before_action :http_header_log
  param_encoding :create, :user_text, Encoding::SHIFT_JIS

  def create
    user_text = params[:user_text]

    logger.info "Sending request to ChatGPT: #{user_text}"
    # chat_gpt_response = get_chat_gpt_response(user_text)
    chat_gpt_response = gpt4(user_text)
    logger.info "Received response from ChatGPT: #{chat_gpt_response}"

    @message = Message.new(user_text:, chat_gpt_response:)

    if @message.save
      render json: { chat_gpt_response: }, status: :created
    else
      render json: @message.errors, status: :unprocessable_entity
    end
  end

  def test
    user_text = params[:user_text]

    logger.info "Sending request to ChatGPT: #{user_text}"
    chat_gpt_response = get_chat_gpt_response(user_text)
    logger.info "Received response from ChatGPT: #{chat_gpt_response}"

    @message = Message.new(user_text:, chat_gpt_response:)

    if @message.save
      render json: { chat_gpt_response: }, status: :created
    else
      render json: @message.errors, status: :unprocessable_entity
    end
  end

  private

  def gpt4(input_text)
    return unless input_text

    api_key = ENV['OPENAI_API_KEY']
    api_endpoint = 'https://api.openai.com/v1/chat/completions'

    prompt = '事業内容から取引を推測して発生しうるテストデータを一日分だけ作成する。事業内容:' + "#{input_text.encode(Encoding::UTF_8)}"
    prompt = '事業内容:' + "#{input_text.encode(Encoding::UTF_8)}"

    # prompt = 'Say this is a test!'
    body = {
      "model": 'gpt-4-0613',
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
                      "description": '入金: income or 出金: expense)'
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
                            "description": ' 取引金額（税込で指定してください）'
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

    response_body = JSON.parse(response.body)
    result1 = response_body['choices'][0]['message']
    logger.info result1

    body = {
      "model": 'gpt-4-0613',
      "temperature": 0.5,
      "messages": [{ "role": 'user', "content": prompt }],
      "functions": [
        {
          "name": 'send_wallet_txn',
          "description": '事業内容から発生しうる取引に対する入金を推測し、入金明細情報を生成する',
          "parameters": {
            "type": 'object',
            "properties": {
              "comment": {
                "type": 'string',
                "description": '発生した入金明細の具体的な内容を決めて、適当に生成する'
              },
              "wallet_txns": {
                "type": 'array',
                "description": ' 入金明細情報をランダムで1から3つ作成する',
                "items": {
                  "type": 'object',
                  "description": '発生した取引に対する、決済情報を明細データとして生成する',
                  "properties": {
                    "entry_side": {
                      "type": 'string',
                      "description": ' income or expense'
                    },
                    "description": {
                      "type": 'string',
                      "description": '取引内容'
                    },
                    "walletable_type": {
                      "type": 'string',
                      "description": 'bank_account or credit_card or wallet'
                    },
                    "date": {
                      "type": 'string',
                      "description": '取引日 (yyyy-mm-dd)'
                    }
                  }
                }
              }
            },
            "required": %w[comment wallet_txns]
          }
        }
      ],
      "function_call": { "name": 'send_wallet_txn' }
    }

    response = RestClient.post(api_endpoint, body.to_json, headers)

    response_body = JSON.parse(response.body)
    result2 = response_body['choices'][0]['message']
    logger.info result2

    response_body['choices'][0]['message']
  end

  def get_chat_gpt_response_copy(input_text)
    return unless input_text

    api_key = ENV['OPENAI_API_KEY']
    api_endpoint = 'https://api.openai.com/v1/chat/completions'

    #  prompt = '入力に対してランダムな明細（wallet_txn）テストデータを生成してください。出力形式：["wallet_txn":{"id":1,"company_id":1,"date":"2019-12-17","amount":5000,"due_amount":0,"balance":10000,"entry_side":"income","walletable_type":"bank_account","walletable_id":1,"description":"振込カ）ABC","status":0,"rule_matched":true}]　入力:' + "#{input_text.encode(Encoding::UTF_8)}"
    prompt = '    ダジャレの面白さをAからEに評価して、評価の理由を論理的にコメントします。ダジャレ:' + "#{input_text.encode(Encoding::UTF_8)}"

    logger.info prompt
    # body = {
    #   "model": 'gpt-3.5-turbo-0301',
    #   "message": [
    #     { 'role': 'user', 'content': prompt }
    #   ],
    #   "max_tokens": 50,
    #   "n": 1,
    #   "stop": nil,
    #   "temperature": 0.1
    # }
    body = {
      # "model": 'gpt-4-0613',
      "model": 'gpt-3.5-turbo-0613',
      "temperature": 0.0,
      "messages": [{ "role": 'user', "content": prompt }],
      # "functions": [
      #   {
      #     "name": 'create_csv',
      #     "description": '明細データをCSVとして作成する',
      #     "parameters": {
      #       "type": 'object',
      #       # プロパティ
      #       "properties": {
      #         "entry_side": {
      #           "type": 'string',
      #           "description": '入金／出金 (入金: income, 出金: expense)'
      #         },
      #         "description": {
      #           "type": 'string',
      #           "description": '取引内容'
      #         },
      #         "walletable_id": {
      #           "type": '	integer',
      #           "description": '口座ID'
      #         },
      #         "walletable_type": {
      #           "type": 'string',
      #           "description": '口座区分 (銀行口座: bank_account, クレジットカード: credit_card, 現金: wallet)'
      #         },
      #         "date": {
      #           "type": 'string',
      #           "description": '取引日 (yyyy-mm-dd)'
      #         },
      #         "company_id": {
      #           "type": 'integer',
      #           "description": '事業所ID'
      #         },
      #         "company_id": {
      #           "type": 'integer',
      #           "description": '残高 (銀行口座等)'
      #         }
      #       },
      #       "required": ['email']
      #     }
      #   }
      # ],
      # function_call={"name": "create_csv"},
      "functions": [
        {
          "name": 'send_dajare_result',
          "description": 'ダジャレの面白さをAからEに評価してコメントします',
          "parameters": {
            "type": 'object',
            "properties": {
              "comment": {
                "type": 'string',
                "description": 'コメント内容'
              },
              "rank": {
                "type": 'string',
                "enum": %w[A B C D E],
                "description": '評価ラベルです。Aが最高、Eが最低です'
              },
              "adovices": {
                "type": 'object',
                "description": '評価結果に対していくつかのアドバイスを返します',
                "properties": {
                  "good": {
                    "type": 'string',
                    "description": 'どのような点が良かったかをアドバイスします'
                  },
                  "bad": {
                    "type": 'string',
                    "description": 'どのような点が悪かったかをアドバイスします'
                  }
                }
              }
            },
            "required": %w[comment rank adovices]
          }
        }
      ],
      "function_call": { "name": 'send_dajare_result' }
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
      logger.error e
      logger.error e.backtrace.join("\n")

      raise 'Charge failed. ErrCode: 500 / ErrMessage: '
    end

    response_body = JSON.parse(response.body)['choices'][0]['message']

    result = JSON.parse(response_body['function_call']['arguments'])

    puts '評価:' + result['rank']
    puts 'コメント:' + result['comment']
    response_body
  end

  def generate_audio(text)
    # 一時ファイルを作成
    temp_file = Tempfile.new(['audio_', '.wav'])

    # eSpeakコマンドを実行して音声データを生成
    system("espeak -w #{temp_file.path} '#{text}'")

    # 一時ファイルのパスを返す
    temp_file.path
  end

  def http_header_log
    logger.info("api_version:#{request.headers[:HTTP_API_VERSION]}")
  end

  # curl http://localhost:5000/messages  -H 'Content-Type: application/json' -d '{"user_text":  "自作キーボードの販売" }'

  def get_chat_gpt_response(input_text)
    return unless input_text

    api_key = ENV['OPENAI_API_KEY']
    api_endpoint = 'https://api.openai.com/v1/chat/completions'

    #  prompt = '入力に対してランダムな明細（wallet_txn）テストデータを生成してください。出力形式：["wallet_txn":{"id":1,"company_id":1,"date":"2019-12-17","amount":5000,"due_amount":0,"balance":10000,"entry_side":"income","walletable_type":"bank_account","walletable_id":1,"description":"振込カ）ABC","status":0,"rule_matched":true}]　入力:' + "#{input_text.encode(Encoding::UTF_8)}"
    prompt = '事業内容から取引を推測して発生しうるテストデータを一日分だけ作成する。事業内容:' + "#{input_text.encode(Encoding::UTF_8)}"

    # logger.info prompt
    body = {
      "model": 'gpt-4-0613',
      # "model": 'gpt-3.5-turbo-0613',
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
                      "description": '入金: income or 出金: expense)'
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
                            "description": ' 取引金額（税込で指定してください）'
                          }
                        }
                      }
                    }
                  }
                }
              }
              # "wallet_txn": {
              #   "type": 'object',
              #   "description": '発生した取引に対する、決済情報を明細データとして生成する',
              #   "properties": {
              #     "entry_side": {
              #       "type": 'string',
              #       "description": '入金／出金 (入金: income, 出金: expense)'
              #     },
              #     "description": {
              #       "type": 'string',
              #       "description": '取引内容'
              #     },
              #     "walletable_id": {
              #       "type": '	integer',
              #       "description": '口座ID'
              #     },
              #     "walletable_type": {
              #       "type": 'string',
              #       "description": '口座区分 (銀行口座: bank_account, クレジットカード: credit_card, 現金: wallet)'
              #     },
              #     "date": {
              #       "type": 'string',
              #       "description": '取引日 (yyyy-mm-dd)'
              #     },
              #     "company_id": {
              #       "type": 'integer',
              #       "description": '事業所ID'
              #     },
              #     "balance": {
              #       "type": 'integer',
              #       "description": '残高 (銀行口座等)'
              #     }
              #   }
              # }
            },
            "required": %w[comment deals]
            # "required": %w[comment]
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
      # logger.error JSON.parse(response)
      # 何らかのエラーが発生した場合はログの書き込みと、
      # エラー通知サービスへの通知を行う
      # logger.error e
      # logger.error e.backtrace.join("\n")

      raise 'get failed. ErrCode: 500 / ErrMessage: ' + e.message
    end

    response_body = JSON.parse(response.body)['choices'][0]['message']

    result = JSON.parse(response_body['function_call']['arguments'])

    # result[0]['deals'].each do |deal|
    #   puts '発生日:' + deal['issue_date']
    #   puts '支払期日:' + deal['due_date']
    #   puts '金額:' + deal['amount']
    #   puts '支払残額:' + deal['due_amount']
    #   puts '入金／出金:' + deal['type']
    #   deal['details'].each do |detail|
    #     puts '税区分名:' + detail['tax']
    #     puts '勘定科目名:' + detail['account_item']
    #     puts '取引金額:' + detail['amount']
    #   end
    # end
  end
end
