require 'fileutils'
require 'logger'
require 'gollum'

class Gitter

  def initialize()
    @workqueue = Queue.new
    Thread.new { worker }
  end

  def repo_path(user, repo)
    "./data/#{user}/#{repo}.wiki"
  end

  def wiki(user, repo)
    options = {
      :base_path => "/#{user}/#{repo}/"
    }

    begin
      wiki = Gollum::Wiki.new(repo_path(user, repo), options)
    rescue Grit::NoSuchPathError, Grit::InvalidGitRepositoryError
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
      begin
        logger.info "getting next work item"
        command = @workqueue.pop
        logger.info "got next work item"
        case command[:op]
        when :clone
          user = command[:user]
          repo = command[:repo]
          logger.info "executing clone #{user}/#{repo}"
          clone(logger, user, repo)
        end
      rescue => error
        logger.error "executing command failed: " + error
      end
    end
  end

  def clone(logger, user, repo)
    logger.info "creating directory #{repo_path(user, repo)}"
    FileUtils.mkdir_p(repo_path(user, repo))
  end

  private :worker
  private :clone
end

