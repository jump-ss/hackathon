# app/controllers/game_controller.rb
class GameController < ApplicationController
  def index; end

  def process_command
    command = params[:command]

    # ここでコマンドを処理します
    # コマンドによって行う処理を分岐させます
    @result = case command
              when 'login'
                'ログイン成功'
              else
                '未知のコマンドです'
              end

    render json: { result: @result }
  end
end
