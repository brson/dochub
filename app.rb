require 'grit'
require 'sinatra/base'
require 'mustache/sinatra'
require 'gitter'
require 'json'

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

  get '/:user/:repo/fetch.apicmd' do
    content_type :json
    result_queue = settings.gitter.fetch(params[:user], params[:repo])
    result_queue.pop.to_json
  end

  get '/:user/:repo/clone.apicmd' do
    content_type :json
    result_queue = settings.gitter.clone(params[:user], params[:repo])
    result_queue.pop.to_json
  end

  get '/:user/:repo/:name' do
    show_page_or_file(params[:user], params[:repo], params[:name])
  end

  get '/:user/:repo' do
    show_page_or_file(params[:user], params[:repo], 'Home')
  end

  get '/:user/:repo/' do
    show_page_or_file(params[:user], params[:repo], 'Home')
  end

  def show_page_or_file(user, repo, name)

    wiki = settings.gitter.wiki(user, repo)

    if !wiki
      return clone_repo_show_page(user, repo, name)
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

  def clone_repo_show_page(user, repo, name)
    @user = user
    @repo = repo
    @name = name
    mustache :clone
  end

  def error_unknown_page(name)
      "I don't know page #{name}"
  end

end
