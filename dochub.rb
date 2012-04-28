require 'sinatra'
require 'gollum'

get '/' do
  'Hello World'
end

get '/:user/:repo' do
  show_page_or_file(params[:user], params[:repo], 'Home')
end

def show_page_or_file(user, repo, name)
  wiki = Gollum::Wiki.new("./data/#{user}/#{repo}.wiki")
  if page = wiki.page(name)
    @page = page
    @name = name
    @content = page.formatted_data
    return @content
  end
end
