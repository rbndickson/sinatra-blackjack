require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'sOgMCZmyqVMwO4g4QJC8'

BLACKJACK_AMOUNT = 21
DEALER_MIN_STAY_AMOUNT = 17
INITIAL_POT_AMOUNT = 500

helpers do

  def make_deck
    suits = %w(S H D C)
    values = %w(A 2 3 4 5 6 7 8 9 10 J Q K)
    deck = suits.product(values)
  end

  def calculate_total(hand)
    sum = 0
    hand.each do |card|
      if ['J', 'Q', 'K'].include?(card[1])
        sum += 10
      elsif card[1] == 'A'
        sum += 11
      else
        sum += card[1].to_i
      end
    end

    hand.select { |card| card[1] == "A" }.count.times do
      sum -= 10 if sum > BLACKJACK_AMOUNT
    end

    sum
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' width='144' height='207' class='card_image'>"
  end

  def winner!(message)
    @show_player_buttons = false
    @hand_finished = true
    session[:players_money] += session[:players_bet].to_i * 2
    @success = message + " - You win $#{session[:players_bet]}!"
    session[:players_bet] = 0
  end

  def loser!(message)
    @show_player_buttons = false
    @hand_finished = true
    if session[:players_money] > 0
      @error = message + " - You lost $#{session[:players_bet]}."
    else
      @error = 'You have run out of money (>_<) Would you like to play again?'
    end
    session[:players_bet] = 0
  end

  def push!(message)
    @show_player_buttons = false
    @alert = message
    @hand_finished = true
    session[:players_money] += session[:players_bet].to_i
  end

  def blackjack?(cards)
    calculate_total(cards) == BLACKJACK_AMOUNT &&
    cards.count == 2
  end

  def busted?(cards)
    calculate_total(cards) > BLACKJACK_AMOUNT
  end

end

before do # this is executed before every get or post
  @show_player_buttons = true
  @show_dealer_button = false
end

get '/' do
  if session.has_key?(:player_name)
    redirect '/game'
  else
    redirect '/name_entry'
  end
end

get '/name_entry' do
  @info = "Welcome to Blackjack! Please enter your name"
  erb :name_entry
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:name_entry)
  end
  session[:player_name] = params[:player_name]
  redirect '/start_over'
end

get '/bet' do
  @info = "You have $#{session[:players_money]}. How much will you bet this round?"
  erb :bet
end

post '/bet' do # Not sure why non ints are rejected here but its good
  if params[:bet].to_i > session[:players_money] || params[:bet].to_i < 1
    @error = "Please enter your bet, you have $" + session[:players_money].to_s
    halt erb(:bet)
  end
  session[:players_bet] = params[:bet]
  session[:players_money] -= session[:players_bet].to_i
  redirect '/game'
end

get '/game' do
  session[:deck] = make_deck.shuffle!
  card_display = {}
  @player_stayed = false

  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  if blackjack?(session[:player_cards])
    redirect '/dealers_turn'
  else
    @info = "Your turn - will you hit or stay?"
  end

  erb :game
end

post '/hit' do
  session[:player_cards] << session[:deck].pop
  if busted?(session[:player_cards])
    loser!("Busted!")
  elsif blackjack?(session[:player_cards])
    winner!("Nice! You have Blackjack!")
  else
    @info = "Your turn - will you hit or stay?"
  end

  erb :game
end

post '/next_dealer_card' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/dealers_turn'
end

get '/dealers_turn' do
  @player_stayed = true
  @show_player_buttons = false

  if blackjack?(session[:player_cards])
    if blackjack?(session[:dealer_cards])
      push!("Push!")
    else
      winner!("You have Blackjack - you win! (^v^)v")
    end
  else
    @info = "Dealers turn - hit next card to see what they have!"
    if calculate_total(session[:dealer_cards]) < DEALER_MIN_STAY_AMOUNT
      @show_dealer_button = true
    elsif busted?(session[:dealer_cards])
      winner!("Dealer has busted - you win!")
    else
      redirect '/compare'
    end
  end

  erb :game
end

post '/stay' do
  redirect '/dealers_turn'
end

get '/compare' do
  @player_stayed = true

  player_score = calculate_total(session[:player_cards])
  dealer_score = calculate_total(session[:dealer_cards])

  if player_score == dealer_score
    push!("It's a push")
  elsif player_score > dealer_score
    winner!("You win!")
  else
    loser!("Dealer wins (>_<)")
  end

  erb :game
end

get '/start_over' do
  session[:players_money] = INITIAL_POT_AMOUNT
  redirect '/bet'
end

get '/finished' do
  @info = "Thank you for playing Blackjack!"

  erb :finished
end
