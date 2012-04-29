require 'gollum'

class Gitter

  def wiki(user, repo)
    options = {
      :base_path => "/#{user}/#{repo}/"
    }

    begin
      wiki = Gollum::Wiki.new("./data/#{user}/#{repo}.wiki", options)
    rescue Grit::NoSuchPathError
      return nil
    end
  end

end

