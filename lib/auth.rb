require 'sinatra/base'
require 'sinatra/flash'
require 'digest/md5'
require './lib/idea_box'

module Sinatra
  module Auth
    module Helpers

      def authorized?
        session[:persona]
      end

      def protected!
        halt 401, slim(:unauthorized) unless authorized?
      end
    end

    def self.registered(app)
      app.helpers Helpers

      app.enable :sessions

      app.get '/session/login' do
        slim :login, locals: {sort: 'rank'}
      end

      app.post '/session/login' do
        user = UserStore.find_by_username(params[:username].downcase)
        login_try = Digest::MD5.hexdigest(params[:password])
        if user && user.password == login_try
          session[:persona] = params[:username]
          user.load_databases
          flash[:notice] = "You are now logged in as #{session[:persona].capitalize}."
          redirect to("/")
        else
          flash[:error] = "The username or password you entered was incorrect."
          redirect to('/session/login')
        end
      end

      app.get '/session/logout' do
        session[:persona] = nil
        flash[:notice] = "You have now logged out."
        redirect to ('/')
      end

      app.get '/session/create' do
        slim :create_user
      end

      app.post '/session/create' do 
        if params[:signup]['password'].nil?
          flash[:error] = "You must enter a password!"
        elsif params[:signup]['password'] != params[:signup]['password_confirmation']
          flash[:error] = "Your password did not match your password confirmation. Please try again."
          redirect '/session/create'
        elsif
          UserStore.find_by_username(params[:signup]['username'].downcase)
          flash[:error] = "Sorry, that username has already been taken. Please try again."
          redirect '/session/create'
        else
          UserStore.create({'username' => params[:signup]['username'].downcase, 'password' => Digest::MD5::hexdigest(params[:signup]['password'].to_s), 'phone' => params[:signup]['phone'], 'email' => params[:signup]['email']})
          flash[:notice] = "Your account was successfully created."
          redirect '/session/login'
        end
      end

      app.get '/session/profile' do
        slim :profile, locals: {user: user, sort: 'rank'}
      end

      app.post '/session/update' do
        if params[:registration][:password] != params[:registration][:password_confirmation]
          flash[:error] = "Your password did not match your password confirmation. Please try again."
          redirect '/session/profile'
        elsif params[:registration][:password].empty?
          flash[:error] = "You must enter a password!"
        elsif params[:registration][:password]
          UserStore.update(user.id, params[:registration].merge({'password' => Digest::MD5::hexdigest(params[:password].to_s)}))
          flash[:success] = "Successfully updated your profile!"
        else
          flash[:error] = "Sorry, there was a problem processing your request."
        end

        redirect '/'
      end

    end

  end
  register Auth
end
