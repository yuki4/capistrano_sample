# -*- coding: utf-8 -*-
require 'rvm/capistrano'
lock '3.2.1'

set :application, 'capistrano_sample'
set :repo_url, 'git@github.com:yuki4/capistrano_sample.git'
set :deploy_to, '/var/www/nginx/capistrano_sample'

set :default_stage, "development"
set :scm, :git
set :deploy_via, :remote_cache

set :log_level, :debug
set :pty, true # sudo ã«å¿è¦
# Shared ã«å¥ããã®ãæå®
set :linked_files, %w{config/database.yml config/secrets.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets bundle public/system public/assets}
# RVM
set :rvm_type, :system
set :rvm1_ruby_version, '2.1'
# Unicorn
set :unicorn_pid, "#{shared_path}/tmp/pids/unicorn.pid"
# 5ååã®releasesãä¿æãã
set :keep_releases, 5

after 'deploy:publishing', 'deploy:restart'
namespace :deploy do
  # ã¢ããªã®åèµ·åãè¡ãã¿ã¹ã¯
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :mkdir, '-p', release_path.join('tmp')
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  # linked_files ã§ä½¿ç¨ãããã¡ã¤ã«ãã¢ããã­ã¼ãããã¿ã¹ã¯
  # deployãè¡ãããåã«å®è¡ããå¿è¦ãããã
  desc 'upload importabt files'
  task :upload do
    on roles(:app) do |host|
      execute :mkdir, '-p', "#{shared_path}/config"
      upload!('config/database.yml',"#{shared_path}/config/database.yml")
      upload!('config/secrets.yml',"#{shared_path}/config/secrets.yml")
    end
  end

  # webãµã¼ãã¼åèµ·åæã«ã­ã£ãã·ã¥ãåé¤ãã
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        execute :rm, '-rf', release_path.join('tmp/cache')
      end
    end
  end

  # Flow ã® before, after ã®ã¿ã¤ãã³ã°ã§ä¸è¨ã¿ã¹ã¯ãå®è¡
  before :started, 'deploy:upload'
  after :finishing, 'deploy:cleanup'

  # Unicorn åèµ·åã¿ã¹ã¯
  desc 'Restart application'
  task :restart do
    invoke 'unicorn:restart' # lib/capustrano/tasks/unicorn.cap åå¦çãå®è¡
  end
end
