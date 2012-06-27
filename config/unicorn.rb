worker_processes 2
user 'deploy'
working_directory "/home/deploy/apps/push_dialer/current"

# This loads the application in the master process before forking
# worker processes
# Read more about it here:
# http://unicorn.bogomips.org/Unicorn/Configurator.html
preload_app true

timeout 30

# This is where we specify the socket.
# We will point the upstream Nginx module to this socket later on
listen "/home/deploy/apps/push_dialer/shared/tmp/sockets/push_dialer.sock", :backlog => 64
pid "/home/deploy/apps/push_dialer/shared/tmp/pids/unicorn.pid"

# Set the path of the log files inside the log folder of the testapp
stderr_path "/home/deploy/apps/push_dialer/shared/log/unicorn.stderr.log"
stdout_path "/home/deploy/apps/push_dialer/shared/log/unicorn.stdout.log"

before_fork do |server, worker|
# This option works in together with preload_app true setting
# What is does is prevent the master process from holding
# the database connection
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
# Here we are establishing the connection after forking worker
# processes
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end

# 
# # config/unicorn.rb
# # Set environment to development unless something else is specified
# env = ENV["RAILS_ENV"] || "development"
# 
# # See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete documentation.
# worker_processes 4
# 
# # listen on both a Unix domain socket and a TCP port,
# # we use a shorter backlog for quicker failover when busy
# listen "/tmp/push_dialer.socket", :backlog => 64
# 
# # Preload our app for more speed
# preload_app true
# 
# # nuke workers after 30 seconds instead of 60 seconds (the default)
# timeout 30
# 
# pid "#{shared_path}/pids/unicorn.pid" #"/tmp/unicorn.push_dialer.pid"
# 
# # Production specific settings
# if env == "production"
#   # Help ensure your application will always spawn in the symlinked
#   # "current" directory that Capistrano sets up.
#   working_directory "/home/deploy/apps/push_dialer/current"
# 
#   # feel free to point this anywhere accessible on the filesystem
#   user 'deploy', 'staff'
#   shared_path = "/home/deploy/apps/push_dialer/shared"
# 
#   stderr_path "#{shared_path}/log/unicorn.stderr.log"
#   stdout_path "#{shared_path}/log/unicorn.stdout.log"
# end
# 
# before_fork do |server, worker|
#   # the following is highly recomended for Rails + "preload_app true"
#   # as there's no need for the master process to hold a connection
#   if defined?(ActiveRecord::Base)
#     ActiveRecord::Base.connection.disconnect!
#   end
# 
#   # Before forking, kill the master process that belongs to the .oldbin PID.
#   # This enables 0 downtime deploys.
#   old_pid = "/tmp/unicorn.push_dialer.pid.oldbin"
#   if File.exists?(old_pid) && server.pid != old_pid
#     begin
#       Process.kill("QUIT", File.read(old_pid).to_i)
#     rescue Errno::ENOENT, Errno::ESRCH
#       # someone else did our job for us
#     end
#   end
# end
# 
# after_fork do |server, worker|
#   # the following is *required* for Rails + "preload_app true",
#   if defined?(ActiveRecord::Base)
#     ActiveRecord::Base.establish_connection
#   end
# 
#   # if preload_app is true, then you may also want to check and
#   # restart any other shared sockets/descriptors such as Memcached,
#   # and Redis.  TokyoCabinet file handles are safe to reuse
#   # between any number of forked children (assuming your kernel
#   # correctly implements pread()/pwrite() system calls)
# end