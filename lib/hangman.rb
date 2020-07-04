require "erb"
require "json"

class Game
  attr_reader :game_data, :man, :prompt, :game_running

  def initialize load = nil
    @game_running = true

    template_file = File.read("template.erb")
    @template = ERB.new(template_file)

    @game_data = load ? load_game : new_game
    @man = build_man
    @prompt = "Enter your guess from the letters available or\n" +
              "attempt to solve. Enter 1 to save and end game:"
  end

  def show_display binding
    system "clear"
    @man = build_man
    display = @template.result(binding)
    puts display
  end

  def get_input
    input = gets.chomp.downcase
    check_input(input)
  end

  private

  def build_man
    turn = @game_data["turn"]
    man = { head: " ",
          body: "   ",
          legs: "   " }
    case turn
    when 2
      man[:head] = "O"
    when 3
      man[:head] = "O"
      man[:body] = " | "
    when 4
      man[:head] = "O"
      man[:body] = "/| "
    when 5
      man[:head] = "O"
      man[:body] = "/|\\"
    when 6
      man[:head] = "O"
      man[:body] = "/|\\"
      man[:legs] = "/  "
    when 7
      man[:head] = "O"
      man[:body] = "/|\\"
      man[:legs] = "/ \\"
      game_end("Sorry, you lose.")
    end
    man
  end

  def get_word
    file = File.open("5desk.txt", "r")
    dictionary = file.readlines.map { |line| line.sub("\r\n", "") }
    dictionary.select! { |line| line.length >= 5 && line.length <= 12 }
    dictionary[rand(dictionary.length)].downcase
  end

  def check_input input
    if input == "1"
      File.open("save/save.json", "w") do |file|
        file.write(@game_data.to_json)
      end
      @prompt = "Game saved."
      @game_running = false
    elsif input.length == 1
      if !@game_data["avail_letters"].include?(input)
        self.get_input
      elsif @game_data["answer"].include?(input)
        update_word_display(input)
        if !@game_data["word_display"].include?("_")
          game_end("You win!")
        end
      else
        @game_data["turn"] += 1
      end
      @game_data["avail_letters"].delete(input)
    elsif input == @game_data["answer"]
      game_end("You guessed the correct word. You win!")
    else
      @game_data["turn"] += 1
    end
  end
  
  def update_word_display letter
    word = @game_data["word_display"].gsub(/\s+/, "")
    @game_data["answer"].chars.each_with_index do |char, index|
      if char == letter
        word[index] = letter
      end
    end
    @game_data["word_display"] = word.chars.join(" ")
  end

  def game_end message
    @prompt = message
    @game_data["word_display"] = @game_data["answer"].chars.join(" ")
    @game_running = false
  end

  def new_game
    avail_letters = ("a".."z").to_a
    answer = get_word
    word_display = ("_" * answer.length).chars.join(" ")
    turn = 1
    return {
      "answer" => answer,
      "word_display" => word_display,
      "avail_letters" => avail_letters,
      "turn" => turn
    }
  end

  def load_game
    save_file = File.read("save/save.json")
    return JSON.parse(save_file)
  end
end

class Menu
  def initialize; end

  def show_menu
    system "clear"
    message = "Welcome to Hangman! Would you like to start a new game or load " +
              "a saved game?\n\n" +
              "(1) Start new game\n" +
              "(2) Load saved game\n" +
              "(3) Exit"
    puts message
    choice = gets.chomp.to_i
    if choice == 1
      play_game
    elsif choice == 2
      if (File.exists?("save/save.json"))
        play_game("load")
      else
        puts "\nCannot find save file."
        sleep(2)
        self.show_menu
      end
    elsif choice == 3
      return
    else
      show_menu
    end
  end

  private
  
  def play_again
    puts "\nWould you like to play again? (y/n)"
    again = gets.chomp
    while again.downcase != "y" && again.downcase != "n"
      puts "\nWould you like to play again? (y)es or (n)o."
      again = gets.chomp
    end
    return again.downcase == "y" ? true : false
  end
  
  def play_game load = nil
    game = Game.new(load)
    game.show_display(binding)
  
    while game.game_running do
      game.get_input
      game.show_display(binding)
    end
  
    show_menu if play_again
  end
end

run_game = Menu.new
run_game.show_menu