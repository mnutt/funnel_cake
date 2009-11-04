namespace :funnel_cake do
  desc 'Copy migration files into main app'
  task :setup => :environment do
    dest = "#{RAILS_ROOT}/db/migrate"
    src = Dir.glob(File.dirname(__FILE__) + "/../db/migrate/*.rb")
    puts "Copying migrations to #{dest}"
    FileUtils.cp(src, dest)

    dest = "#{RAILS_ROOT}/public"
    src = Dir.glob(File.dirname(__FILE__) + "/../public/*")
    puts "Copying assets to #{dest}"
    FileUtils.cp_r(src, dest)

    #
    # Generate xdot code
    #
    erbcode = File.open(File.dirname(__FILE__) + "/_diagram.dot.erb").read
    dotcode = ERB.new(erbcode, nil, '-').result(binding)

    r = IO.popen("dot -Txdot ", "w+")
    r.write(dotcode + "\n")
    r.close_write
    xdot = r.read

    FileUtils.mkdir_p(File.join(RAILS_ROOT, 'app', 'views', 'analytics', 'dashboards'))
    w = File.open(File.join(RAILS_ROOT, 'app', 'views', 'analytics', 'dashboards', '_diagram.xdot.erb'), 'w')
    w.write(xdot)
    w.close
  end
end