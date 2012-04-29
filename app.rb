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
      return show_add_repo(user, repo, name)
    end

    if page = wiki.page(name)
      @page = page
      @name = name
      mustache :page
    end
  end

  def show_add_repo(user, repo, name)
    @user = user
    @repo = repo
    @name = name
    mustache :addrepo
  end

end
