require 'rest-client'

class MessagesController < ApiController
  skip_before_action :verify_authenticity_token
  before_action :http_header_log
  # param_encoding :create, :user_text, Encoding::SHIFT_JIS

  def create
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

  def get_chat_gpt_response(input_text)
    return unless input_text

    api_key = ENV['OPENAI_API_KEY']
    api_endpoint = 'https://api.openai.com/v1/chat/completions'

    prompt = 'お嬢様言葉で入力に対して返信してください。入力:' + "#{input_text.encode(Encoding::UTF_8)}"
    # prompt = 'Say this is a test!'

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
      "model": 'gpt-3.5-turbo',
      "messages": [{ "role": 'user', "content": prompt }],
      "temperature": 0
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

    response_body = JSON.parse(response.body)

    response_body['choices'][0]['message']
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
end
