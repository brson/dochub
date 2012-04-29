require 'logger'
require 'gollum'

class Gitter

  def initialize()
    @workqueue = Queue.new
    Thread.new { worker }
  end

  def wiki(user, repo)
    options = {
      :base_path => "/#{user}/#{repo}/"
    }

    begin
      wiki = Gollum::Wiki.new("./data/#{user}/#{repo}.wiki", options)
    rescue Grit::NoSuchPathError
      add_work_item({
        :op => :clone,
        :user => user,
        :repo => repo
      })
      return nil
    end
  end

  def add_work_item(command)
    @workqueue.push(command)
  end

  def worker()
    logger = Logger.new(STDOUT)

    logger.info "starting worker"

    while true
      logger.info "getting next work item"
      command = @workqueue.pop
      logger.info "got next work item"
      case command[:op]
      when :clone
        user = command[:user]
        repo = command[:repo]
        logger.info "executing clone #{user}/#{repo}"
        clone(user, repo)
      end
    end
  end

  def clone(user, repo)
  end

  private :worker
  private :clone
end

