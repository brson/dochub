require 'fileutils'
require 'logger'
require 'gollum'
require 'grit'

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
    if is_repo_ready(logger, user, repo)
      logger.info "repo is already ready"
      return
    end

    path = repo_path(user, repo)
    remote = "git://github.com/#{user}/#{repo}.wiki"

    logger.info "deleting directory #{path}"
    FileUtils.rm_rf(path)

    logger.info "creating directory #{path}"
    FileUtils.mkdir_p(path)

    logger.info "initing repo #{path}"
    repo = Grit::Repo.init(path)

    logger.info "adding remote " + remote
    repo.remote_add("origin", remote);

    logger.info "fetching origin"
    repo.remote_fetch("origin")

    logger.info "reset origin/master"
    # FIXME: This --hard doesn't do anything and the working dir
    # ends up not containing anything
    repo.git.native(:reset, {:hard => true}, ["origin/master"])
  end

  def is_repo_ready(logger, user, repo)
    begin
      wiki = Gollum::Wiki.new(repo_path(user, repo))
      wiki.exist?
    rescue => error
      logger.info "repo is not ready: " + error
      false
    end
  end

  private :worker
  private :clone
end

