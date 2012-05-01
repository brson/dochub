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
      # Get it ready for next time
      clone(user, repo)
      return nil
    end
  end

  def clone(user, repo)
    add_work_item({
                    :op => :clone,
                    :user => user,
                    :repo => repo
                  })
  end

  def fetch(user, repo)
    add_work_item({
                    :op => :fetch,
                    :user => user,
                    :repo => repo
                  })
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
          do_clone(logger, user, repo)
        when :fetch
          user = command[:user]
          repo = command[:repo]
          logger.info "executing fetch #{user}/#{repo}"
          do_fetch(logger, user, repo)
        end
      rescue => error
        logger.error "executing command failed: " + error
      end

      delay = 2
      logger.info "sleeping #{delay} s"
      sleep delay
    end
  end

  def do_clone(logger, user, repo)
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

  def do_fetch(logger, user, repo)
    if !is_repo_ready(logger, user, repo)
      logger.info "repo #{user}/#{repo} wasn't ready to fetch"
      return
    end

    logger.info "fetching origin"
    grepo = Grit::Repo.new(repo_path(user, repo))
    grepo.git.native(:fetch, {:depth => 1, :raise => true}, "origin")
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
  private :do_clone
  private :do_fetch
  private :new_wiki
end

