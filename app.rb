require 'grit'
require 'sinatra/base'
require 'gollum'
require 'mustache/sinatra'

class App < Sinatra::Base
  register Mustache::Sinatra
  require 'views/layout'

  set :public_folder, "./public"

  set :mustache, {
    :templates => "./templates",
    :views => "./views"
  }

  get '/' do
    'Welcome to dochub'
  end

  get '/:user/:repo/:name' do
    show_page_or_file(params[:user], params[:repo], params[:name])
  end

  get '/:user/:repo' do
    show_page_or_file(params[:user], params[:repo], 'Home')
  end

  def show_page_or_file(user, repo, name)

    options = {
      :base_path => "/#{user}/#{repo}/"
    }

    begin
      wiki = Gollum::Wiki.new("./data/#{user}/#{repo}.wiki", options)
    rescue Grit::NoSuchPathError
      return error_unknown_repo(user, repo)
    end

    if page = wiki.page(name)
      @page = page
      @user = user
      @repo = repo
      @name = name
      mustache :page
    else
      error_unknown_page(name)
    end
  end

  def error_unknown_repo(user, repo)
    "I don't know #{user} / #{repo} yet"
  end

  def error_unknown_page(name)
      "I don't know page #{name}"
  end

end
