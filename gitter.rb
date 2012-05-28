require 'fileutils'
require 'logger'
require 'gollum'
require 'grit'

class Gitter

  def initialize()
    @logger = Logger.new(STDOUT)
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
      @logger.info "don't have #{user}/#{repo}"
      return nil
    end
  end

  def clone(user, repo)
    result_queue = Queue.new
    add_work_item({
                    :op => :clone,
                    :user => user,
                    :repo => repo,
                    :result_queue => result_queue
                  })
    result_queue
  end

  def fetch(user, repo)
    result_queue = Queue.new
    add_work_item({
                    :op => :fetch,
                    :user => user,
                    :repo => repo,
                    :result_queue => result_queue
                  })
    result_queue
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
          result_queue = command[:result_queue]
          logger.info "executing clone #{user}/#{repo}"
          do_clone(logger, user, repo, result_queue)
        when :fetch
          user = command[:user]
          repo = command[:repo]
          result_queue = command[:result_queue]
          logger.info "executing fetch #{user}/#{repo}"
          do_fetch(logger, user, repo, result_queue)
        end
      rescue => error
        logger.error "executing command failed: " + error
      end
    end
  end

  def do_clone(logger, user, repo, result_queue)
    begin
      if is_repo_ready(logger, user, repo)
        logger.info "repo is already ready"
        result_queue.push(:result => :ok)
        return
      end

      path = repo_path(user, repo) + ".tmp"
      final_path = repo_path(user, repo)
      remote = "git://github.com/#{user}/#{repo}.wiki"

      logger.info "deleting directory #{path}"
      FileUtils.rm_rf(path)

      logger.info "deleting directory #{final_path}"
      FileUtils.rm_rf(final_path)

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
        raise
      end

      logger.info "moving repo into place"
      begin
        FileUtils.mv(path, final_path)
      rescue => error
        logger.error "couldn't move repo #{user}/#{repo} " + error
        FileUtils.rm_rf(final_path)
        FileUtils.rm_rf(path)
        raise
      end

      result_queue.push(:result => :ok)

    rescue => error
      logger.error "unexpected error #{user}/#{repo}" + error
      result_queue.push(:result => :err)
      raise
    end
  end

  def do_fetch(logger, user, repo, result_queue)
    begin

      if !is_repo_ready(logger, user, repo)
        logger.info "repo #{user}/#{repo} wasn't ready to fetch"
        result_queue.push(:result => :ok)
        return
      end

      logger.info "fetching origin"
      grepo = Grit::Repo.new(repo_path(user, repo))
      grepo.git.native(:fetch, {:depth => 1, :raise => true}, "origin")

      result_queue.push(:result => :ok)

    rescue
      result_queue.push(:result => :err)
      raise
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
  private :do_clone
  private :do_fetch
  private :new_wiki
end

