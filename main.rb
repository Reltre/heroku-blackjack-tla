require 'rubygems'
require 'sinatra'
require 'pry'
require 'json'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'BVL57Q' 

BLACKJACK_AMOUNT = 21
DEALER_HIT_MIN = 17
INITIAL_POT_AMOUNT = 500

helpers do 
  def calculate_total(cards)
    result = cards.inject(0) do |sum,card| 
      if card[1] == 'ace'
        sum + 11
      else 
        sum + (card[1].to_i == 0 ? 10 : card[1]) 
      end
    end
    cards.select{ |card| card[1] == 'ace' }.count.times do 
      break if result <= BLACKJACK_AMOUNT
      result -= 10 
    end
    result
  end

  def card_image(card)
    "<img src=/images/cards/#{card.join('_')}.jpg>"
  end

  def compare_hands
    dealer_total = calculate_total(session[:dealer_hand])
    player_total = calculate_total(session[:player_hand])

    if player_total == dealer_total 
      "tie"
    elsif dealer_total > player_total
      "loss"
    else 
      "win"
    end
  end

  def compare_blackjack
    if blackjack?(session[:player_hand]) && blackjack?(session[:dealer_hand]) 
      "blackjack_tie"
    elsif blackjack?(session[:dealer_hand])
      "blackjack_loss"
    else
      "blackjack_win"
    end
  end

  def deal_card(hand)
    session[hand] << session[:deck].pop
  end

  def blackjack?(cards)
    cards.size == 2 && calculate_total(cards) == BLACKJACK_AMOUNT
  end
end

not_found do
  erb :no_such_page
end

before do
  @show_hit_or_stay = true
  @show_card_cover = true
end

get '/' do
  if session[:player_name]
    redirect '/bet'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  session[:money] = INITIAL_POT_AMOUNT
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  redirect '/bet' 
end

get '/bet' do 
  session[:bet_amount] = nil
  erb :bet_form
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i <= 0
    @error = "Please enter a bet amount."
    halt erb(:bet_form)
  elsif params[:bet_amount].to_i > session[:money] 
    @error = "Bet amount cannot be greater than your
    current funds: $#{session[:money]}"
    halt erb(:bet_form)
  else
    session[:bet] = params[:bet_amount].to_i  
  end 
  redirect '/game'
end

get '/game' do
  values = [2, 3, 4, 5, 6, 7, 8, 9, 10, 'jack', 'queen', 'king', 'ace']
  suits = ["clubs", "spades", "hearts", "diamonds"]
  session[:deck] = suits.product(values).shuffle!
  session[:player_hand] = []
  session[:dealer_hand] = []
  deal_card(:dealer_hand)
  deal_card(:player_hand)
  deal_card(:dealer_hand)
  deal_card(:player_hand)
  erb :game
end

get '/game_state' do 
  dealer_total = calculate_total(session[:dealer_hand])
  @show_card_cover = false
  @show_hit_or_stay = false
  @show_dealer_total = true
  @dealer_turn = true  
  @info = "You decided to stay"
  @show_only_player_total = true

  if dealer_total > BLACKJACK_AMOUNT
    @success = "The Dealer has busted, #{session[:player_name]} wins!"
    @dealer_turn = false
    halt erb(:game)
  elsif (dealer_total >= DEALER_HIT_MIN) &&
   (dealer_total <= BLACKJACK_AMOUNT || blackjack?(session[:dealer_hand]))
    redirect '/game/comparison'
  end
  erb :game, :layout => !request.xhr? 
end

post '/game/player-hit' do 
  deal_card(:player_hand) 
  if calculate_total(session[:player_hand]) > BLACKJACK_AMOUNT
    @error = 
    "Sorry,#{session[:player_name]}
    busted with a total of 
    #{calculate_total session[:player_hand]}."
    @show_hit_or_stay = false
    @round_over = true
    halt erb(:game)
  end
  erb :game, :layout => !request.xhr? 
end

get '/game/stats' do
  calculate_total(session[:dealer_hand]).to_s
end

post '/game/dealer-hit' do
  deal_card(:dealer_hand)
  redirect 'game_state'
end

#Implement this in JS()
get '/game/comparison' do
  result = 
  if (blackjack?(session[:dealer_hand]) || blackjack?(session[:player_hand]))
    compare_blackjack
  else
    compare_hands
  end
  @show_card_cover = false
  @show_hit_or_stay = false
  @dealer_turn = false
  @show_dealer_total = true

  @success = "#{session[:player_name]} wins!" if result == "win"
  @alert = "The round ended in a tie." if result == "tie"
  @error = "The Dealer won the round." if result == "loss"
  @show_only_player_total = true

  if result == "blackjack_win"
    @success = "#{session[:player_name]} has BlackJack and wins!"
  elsif result == "blackjack_tie"
    @alert = "Both #{session[:player_name]} and the Dealer have BlackJack, the round ends in a tie."
  elsif result == "blackjack_loss"
    @error = "The Dealer has BlackJack and wins the round." 
  end
  
  erb :game
end

get '/end-game' do
  if session[:player_name]
    erb :game_over
  else
   redirect '/'
  end
end