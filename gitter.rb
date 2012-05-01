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
    "./data/#{user}/#{repo}.wiki.git"
  end

  def wiki(user, repo)

    begin
      wiki = new_wiki(user, repo)
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

    logger.info "initing repo #{path}"
    grepo = Grit::Repo.init_bare(path)

    logger.info "adding remote " + remote
    grepo.remote_add("origin", remote);

    logger.info "fetching origin"
    begin
      grepo.git.native(:fetch, {:depth => 1, :raise => true}, "origin")
    rescue => error
      logger.error "couldn't fetch origin from #{user}/#{repo}" +
        "because of " + error
      FileUtils.rm_rf(path)
    end

  end

  def is_repo_ready(logger, user, repo)
    begin
      new_wiki(user, repo).exist?
    rescue => error
      logger.info "repo #{user}/#{repo} is not ready: " + error
      false
    end
  end

  def new_wiki(user, repo)
    options = {
      :base_path => "/#{user}/#{repo}/",
      :ref => "origin/master"
    }

    Gollum::Wiki.new(repo_path(user, repo), options)
  end

  private :worker
  private :clone
  private :new_wiki
end

