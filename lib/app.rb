require 'slim'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/assetpack'
require 'sinatra/flash'
require 'better_errors'
require 'sass'
require './lib/idea_box'
require './lib/sinatra/auth'


class IdeaBoxApp < Sinatra::Base

  enable :sessions
  set :session_secret, 'The magic word'
  set :method_override, true
  set :root, 'lib/app'

  register Sinatra::Auth
  register Sinatra::AssetPack
  register Sinatra::Flash

  assets {
    serve '/javascripts', from: 'javascripts'
    js :foundation, [
      'javascripts/foundation/foundation.js',
      'javascripts/foundation/foundation.*.js'
    ]

    js :application, [
      '/javascripts/vendor/*.js',
      '/javascripts/app.js'
    ]

    serve '/stylesheets', from: 'stylesheets'
    css :application, [
      '/stylesheets/normalize.css',
      '/stylesheets/app.css'
    ]

    js_compression :jsmin
    css_compression :sass
  }

  def user
    @user ||= UserStore.find_by_username(session[:persona])
  end

  def set_dbs
    user.load_databases
  end

  configure :development do
    register Sinatra::Reloader
    use BetterErrors::Middleware
    BetterErrors.application_root = 'lib/app'
  end

  not_found do
    slim :error
  end

  get '/' do
    if session[:persona]
      set_dbs
      @idea = IdeaStore.all.sort.first
      slim :index, locals: { ideas: IdeaStore.all.sort, user: user, idea: @idea, show_resources: false, mode: 'new' }
    else
      slim :login
    end
  end

  get '/sorted_tags' do
    ideas = IdeaStore.sort_all_by_tags.values.flatten
    slim :index, locals: { ideas: ideas, user: user, idea: ideas.first, show_resources: false, mode: 'new' }
  end

  get '/sorted_days' do
    ideas = IdeaStore.group_all_by_day_created.values.flatten
    slim :index, locals: { ideas: ideas, user: user, idea: ideas.first, show_resources: false, mode: 'new' }
  end

  post '/ideas/:id' do
    protected!
    flash[:notice] = "Idea successfully added" if IdeaStore.create(params[:idea])
    redirect "/"
  end

  get '/new' do
    protected!
    slim :index, locals: { ideas: IdeaStore.all.sort, user: user, idea: Idea.new, show_resources: false, mode: 'new' }
  end

  get '/ideas/:id' do |id|
    protected!
    idea = IdeaStore.find(id)
    history = RevisionStore.find_all_by_idea_id(id.to_i)
    slim :show, locals: { idea: idea, user: user, show_resources: true, history: history }
  end

  get '/ideas/:id/edit' do |id|
    protected!
    idea = IdeaStore.find(id.to_i)
    slim :index, locals: { idea: idea, user: user, ideas: IdeaStore.all.sort, show_resources: false, mode: "edit" }
  end

  put '/ideas/:id' do |id|
    protected!
    IdeaStore.update(id.to_i, params[:idea])
    redirect '/'
  end

  delete '/ideas/:id' do |id|
    protected!
    IdeaStore.delete(id.to_i)
    redirect '/'
  end

  post '/ideas/:id/like' do |id|
    protected!
    idea = IdeaStore.find(id.to_i)
    idea.like!
    IdeaStore.update(id.to_i, idea.to_h)
    redirect '/'
  end

  get '/all/tags/:tag' do |tag|
    protected!
    slim :tag_view, locals: { tag: tag, user: user }
  end

  post '/search/results' do
    protected!
    results = IdeaStore.search_for(params[:search_text])
    slim :search, locals: { search: params[:search_text], user: user, time_range: nil, results: results }
  end

  post '/search/time/results' do
    protected!
    time_range = params[:time_range].split("-")
    results = IdeaStore.find_all_by_time_created(time_range[0], time_range[1])
    slim :search, locals: { search: "All Ideas Created Between #{time_range[0]} and #{time_range[1]}", results: results, user: user }
  end

  post '/search/tags/results' do
    protected!
    results = IdeaStore.sort_all_by_tags
    slim :search, locals: { search: "All Ideas Sorted By Tags", results: results, user: user }
  end

  post '/search/day/results' do
    protected!
    results = IdeaStore.group_all_by_day_created
    slim :search, locals: { search: "All Ideas Sorted By Day", results: results, user: user }
  end

  get '/portfolios/:value' do |value|
    protected!
    UserStore.load_portfolio_for(user.id, value)
    flash[:notice] = "Successfully loaded your #{value.capitalize} repository."
    redirect '/'
  end

end