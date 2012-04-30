require 'cgi'

module Views
  class Layout < Mustache
    include Rack::Utils

    def title
      "dochub"
    end
  end
end
