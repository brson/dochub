require 'grit'
require 'sinatra/base'
require 'mustache/sinatra'
require 'gitter'

class App < Sinatra::Base
  register Mustache::Sinatra
  require 'views/layout'

  configure :production, :development do
    enable :logging
  end

  set :public_folder, "./public"

  set :mustache, {
    :templates => "./templates",
    :views => "./views"
  }

  set :gitter, Gitter.new

  get '/' do
    show_page_or_file('brson', 'dochub', 'Home')
  end

  get '/:user/:repo/fetch' do
    settings.gitter.fetch(params[:user], params[:repo])
  end

  get '/:user/:repo/:name' do
    show_page_or_file(params[:user], params[:repo], params[:name])
  end

  get '/:user/:repo' do
    show_page_or_file(params[:user], params[:repo], 'Home')
  end

  def show_page_or_file(user, repo, name)

    wiki = settings.gitter.wiki(user, repo)

    if !wiki
      return error_unknown_repo(user, repo)
    end

    if page = wiki.page(name)
      @page = page
      @user = user
      @repo = repo
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
