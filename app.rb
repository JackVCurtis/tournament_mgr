require 'sinatra'
require 'sinatra/activerecord'

# Don't forget to add database name in config/database.yml
require_relative './models/user.rb'
require_relative './models/match.rb'
require_relative './models/player.rb'
require_relative './models/tournament.rb'
require_relative './models/pool.rb'
require_relative './config/environments'

enable :sessions

helpers do
  def current_user
    @current_user || nil
  end

  def current_user?
    @current_user == nil ? false : true
  end
end

before do
  @errors ||= []
  @current_user = User.find_by(id: session[:user_id])
end

before /user/ do
  unless current_user?
    @errors << "Please sign up or log in."
    redirect "/"
  end
end

get '/' do
  @tournaments = Tournament.all
	erb :index
end

get '/signup' do
	erb :signup
end

post '/signup' do
	user = User.new(params)
  if user.save
    session[:user_id] = user.id
    redirect('/user')
  else
    @user = user
    erb :signup
  end
end

get '/login' do
	erb :login
end

post '/login' do
	user = User.find_by(email: params[:email])
  if user && user.authenticate(params[:password])
    session[:user_id] = user.id
    redirect('/user')
  else
    @errors << "Invalid email or password. Try again!"
    erb :login
  end
end

get '/logout' do
  session.clear
  redirect('/')
end

get "/user" do
  if @current_user.tournaments
    @tournaments = Tournament.where(user_id: session[:user_id])
  else
    @tournaments = []
  end
  erb :user
end

post "/user" do
  Tournament.create(name: params[:name], user_id: session[:user_id])
  redirect "/user"
end

get "/user/tournament/:tournament_id" do
  session[:tournament_id] = params["tournament_id"]

  @tournament = Tournament.find(params["tournament_id"]) #doesn't validate user
  
  @players = Player.where(tournament_id: @tournament.id)
  @players ||= []

  erb :user_tournament

end

get "/tournament/:tournament_id" do
  @tournament = Tournament.find(params["tournament_id"])

  erb :tournament
end

post "/tournament/:tournament_id" do
  player = Player.new(
    name: params[:name],
    weight: params[:weight],    
    age: params[:age],
    gender: params[:gender],
    rank: params[:rank],
    )
  player.tournament = Tournament.find(params["tournament_id"])
  player.save

  redirect "/tournament/#{params["tournament_id"]}"
end

get "/user/player/:player_id" do
  @player = Player.find(params["player_id"])
  erb :user_player
end

post "/user/player/:player_id" do
  Player.update(
    params["player_id"],
    name: params[:name],
    weight: params[:weight],    
    age: params[:age],
    gender: params[:gender],
    rank: params[:rank],
    )
  redirect "/user/player/#{params["player_id"]}"
end

delete "/user/player/:player_id" do
  Player.destroy(params["player_id"])

  redirect "/user/tournament/#{session[:tournament_id]}"
end

get "/user/tournament/:tournament_id/pools" do
  @tournament = Tournament.find(params["tournament_id"])

  if @tournament.pools
    @pools = @tournament.pools
  else
    @pools = []
  end

  erb :user_tournament_pools
end

post "/user/tournament/:tournament_id/pools" do
  pool = Pool.new(
    name: params[:name],
    gender: params[:gender],
    rank: params[:rank],
    min_weight: params[:min_weight],
    max_weight: params[:max_weight],
    min_age: params[:min_age],
    max_age: params[:max_age]
    )
  pool.tournament = Tournament.find(params["tournament_id"])
  pool.save

  redirect "/user/tournament/#{params["tournament_id"]}/pools"
end

get "/user/tournament/:tournament_id/pools/:pool_id" do
  @tournament = Tournament.find(params["tournament_id"])
  @pool = Pool.find(params["pool_id"])
  @players = @pool.players
  erb :user_tournament_pool
end

post "/user/tournament/:tournament_id/pools/:pool_id" do
  pool = Pool.update(
    name: params[:name],
    gender: params[:gender],
    rank: params[:rank],
    min_weight: params[:min_weight],
    max_weight: params[:max_weight],
    min_age: params[:min_age],
    max_age: params[:max_age]
    )

redirect "/user/tournament/#{params["tournament_id"]}/pools/#{params["pool_id"]}"
end

delete "/user/tournament/:tournament_id/pools/:pool_id" do
  Player.destroy(params["pool_id"])

  redirect "/user/tournament/#{params["tournament_id"]}/pools"
end

get "/user/tournament/:tournament_id/pool_players" do
  @players = Player.where(tournament_id: params["tournament_id"])

  @players.each do |player|
    unless player.add_to_pool
      @errors << "No pool available for #{player.name}"
    else
      player.save
    end
  end

  redirect "/user/tournament/#{params["tournament_id"]}/pools"
end








