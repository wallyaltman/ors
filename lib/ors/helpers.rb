module ORS
  module Helpers

    include Config

    def setup_repo server
      info "[#{server}] installing codebase..."

      remote_execute server, %(cd #{ORS:Config.base_path}),
                             %(rm -rf #{deploy_directory}),
                             %(git clone #{REPO}:#{name} #{deploy_directory}),
                             %(mkdir -p #{deploy_directory}/tmp/pids),
                             %(mkdir -p #{deploy_directory}/log)
    end

    def setup_ruby server
      info "[#{server}] installing ruby and gems..."

      remote_execute server, %(source ~/.rvm/scripts/rvm),
                             %(cd #{deploy_directory}),
                             %(gem install rubygems-update),
                             %(gem update --system),
                             %(gem install bundler),
                             %(bundle install --without development test osx > bundler.log)
    end

    def update_code server
      info "[#{server}] updating codebase..."

      remote_execute server, %(cd #{deploy_directory}),
                             %(git fetch),
                             %(git checkout -q -f origin/#{environment}),
                             %(git reset --hard)
    end

    def bundle_install server
      info "[#{server}] installing bundle..."

      remote_execute server, %(source ~/.rvm/scripts/rvm),
                             %(cd #{deploy_directory}),
                             %(bundle install --without development test osx > bundler.log)
    end

    def start_server server
      info "[#{server}] starting unicorn..."

      remote_execute server, %(source ~/.rvm/scripts/rvm),
                             %(cd #{deploy_directory}),
                             %(bundle exec #{unicorn} -c config/unicorn.rb -D -E #{environment})
    end

    def stop_server server
      info "[#{server}] stopping unicorn..."

      remote_execute server, %(cd #{deploy_directory}),
                             %(kill \\`cat tmp/pids/unicorn.pid\\`)
    end

    def restart_server server
      info "[#{server}] restarting unicorn..."

      remote_execute server, %(cd #{deploy_directory}),
                             %(kill -USR2 \\`cat tmp/pids/unicorn.pid\\`)
    end

    def run_migrations server
      info "[#{server}] running migrations..."

      remote_execute server, %(cd #{deploy_directory}),
                             %(RAILS_ENV=#{environment} rake db:migrate db:seed)
    end

    def execute_in_parallel servers
      servers.map do |server|
        Thread.new(server) do |server|
          yield server
        end
      end.map {|thread| thread.join }
    end

    def remote_execute server, *command_array
      commands = command_array.join " && "

      if use_gateway
        command = %(ssh #{gateway} 'ssh #{deploy_user}@#{server} "#{commands}"')
      else
        command = %(ssh #{deploy_user}@#{server} "#{commands}")
      end

      (pretending ? command : %x[#{command}]).split("\n").each do |result|
        info("[#{server}] #{result}")
      end
    end

    def info message
      STDOUT.puts message
    end

    def fatal message
      info message
      exit 1
    end

  end
end
