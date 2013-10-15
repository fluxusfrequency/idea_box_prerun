require 'haml'
require 'better_errors'
require 'sinatra/base'
require_relative './idea_box/idea.rb'
require_relative './idea_box/idea_store.rb'


class IdeaBoxApp < Sinatra::Base

  set :method_override, true
  set :root, 'lib/app'

  configure :development do
    use BetterErrors::Middleware
    BetterErrors.application_root = __dir__
  end

  not_found do
    haml :error
  end

  get '/' do
    haml :index , locals: {:ideas => IdeaStore.all.sort, :idea => Idea.new}
  end

  post '/' do
    IdeaStore.create(params[:idea])
    redirect '/'
  end

  get '/:id/edit' do |id|
    idea = IdeaStore.find(id.to_i)
    haml :edit, locals: {idea: idea}
  end

  put '/:id' do |id|
    IdeaStore.update(id.to_i, params[:idea])
    redirect '/'
  end

  delete '/:id' do |id|
    IdeaStore.delete(id.to_i)
    redirect '/'
  end

  post '/:id/like' do |id|
    idea = IdeaStore.find(id.to_i)
    idea.like!
    IdeaStore.update(id.to_i, idea.to_h)
    redirect '/'
  end

end