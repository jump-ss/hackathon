class Game
  attr_accessor :player

  def initialize
    @player = Player.new
  end

  def start
    puts 'Welcome to the Startup Simulation!'
    puts "What's your name?"
    @player.name = gets.chomp
    puts "Hi #{@player.name}! Let's get your startup off the ground."
    # ゲームのロジックをここに書く
  end
end
