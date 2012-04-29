require 'sinatra/base'
require 'gollum'
require 'mustache/sinatra'

class App < Sinatra::Base
  register Mustache::Sinatra
  require 'views/layout'

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
    wiki = Gollum::Wiki.new("./data/#{user}/#{repo}.wiki", options)
    if page = wiki.page(name)
      @page = page
      @name = name
      @content = page.formatted_data
      mustache :page
    end
  end
end
