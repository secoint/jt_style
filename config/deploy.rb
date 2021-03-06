# У вас должна быть настроена авторизация ssh по сертификатам

set :application, "jt-style"

# настройка системы контроля версий и репозитария, по умолчанию - git, если используется иная система версий, нужно изменить значение scm
set :scm, :git
set :repository,  "git://github.com/secoint/jt_style.git"

set :user, "hosting_filippovaw"
set :use_sudo, false
set :deploy_to, "/home/#{user}/projects/jt-style"

role :web, "lithium.locum.ru"   # Your HTTP server, Apache/etc
role :app, "lithium.locum.ru"   # This may be the same as your `Web` server
role :db,  "lithium.locum.ru", :primary => true # This is where Rails migrations will run

set :unicorn_rails, "/var/lib/gems/1.8/bin/unicorn_rails"
set :bundler, "/var/lib/gems/1.8/bin/bundle"
set :rails, "/var/lib/gems/1.8/bin/rails"
set :rake, "/var/lib/gems/1.8/bin/rake"

# эта секция для того, чтобы вы не хранили доступ к базе в системе контроля версий. Поместите dayabase.yml в shared,
# чтобы он копировался в нужный путь при каждом выкладывании новой версии кода
# так лучше с точки зрения безопасности, но если не хотите - прсото закомментируйте этот таск


# Если хотите поместить конфиг в shared и не хранить его в системе контроя версий - раскомментируйте следующие строки

after "deploy:update_code", :copy_database_config

task :copy_database_config, roles => :app do
  db_config = "#{shared_path}/database.yml"
  run "cp #{db_config} #{release_path}/config/database.yml"
  run "ln -s #{shared_path}/assets #{release_path}/public/assets"
  run ["cd #{deploy_to}/current",
       "rvm use ree-1.8.7-2011.03 do bundle install --path ../../shared/gems",
       "#{bundler} exec #{rake} jt_style_theme:install"].join(" && ")
end

set :unicorn_conf, "/etc/unicorn/jt-style.filippovaw.rb"
set :unicorn_pid, "/var/run/unicorn/jt-style.filippovaw.pid"

set :unicorn_start_cmd, "(cd #{deploy_to}/current; rvm use ree-1.8.7-2011.03 do bundle exec unicorn_rails -Dc #{unicorn_conf})"

# - for unicorn - #
namespace :deploy do
  desc "Start application"
  task :start, :roles => :app do
    run ["cd #{deploy_to}/current",
        "rvm use ree-1.8.7-2011.03 do bundle install --path ../../shared/gems",
        unicorn_start_cmd].join(" && ")
  end

  desc "Stop application"
  task :stop, :roles => :app do
    run "[ -f #{unicorn_pid} ] && kill -QUIT `cat #{unicorn_pid}`"
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "[ -f #{unicorn_pid} ] && kill -USR2 `cat #{unicorn_pid}` || #{unicorn_start_cmd}"
  end
end

