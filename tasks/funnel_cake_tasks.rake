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


  namespace :mongodb do
    ATTRIB_HASH = {
      'referer'     =>'referer',
      'user_agent'  =>'user_agent',
      'url'         =>'landing_page',
    }

    def send_to_mongo(code)
      IO.popen("mongo", "w+") do |mongo|
        mongo.write(code.join("\n"))
        mongo.close_write
        puts mongo.read
      end
    end

    desc 'Run map-reduce aggregations on existing visitor data to build statistics collections'
    task :build_statistics do
      ATTRIB_HASH.each do |attrib, collection|
        puts "---------- Building collection #{collection} from events[0].#{attrib}..."
        code = []
        code << 'use funnelcake;'
        code << "m = function(){ emit( (this.events && this.events[0] && this.events[0].#{attrib}) ? this.events[0].#{attrib} : null, {count: 1}) };"
        code << "r = function( key , values ){  var total = 0; for ( var i=0; i<values.length; i++) { total += values[i].count; } return { count : total }; };"
        code << "db.analytics.visitors.mapReduce(m, r, {out: 'analytics.statistics.#{collection.pluralize}'});"
        code << "db.analytics.statistics.#{collection.pluralize}.ensureIndex({'value.count':-1});"

        send_to_mongo(code)
        puts "---------- DONE. moving on...."
      end
    end

    desc 'Drop existing visitor statistics collections'
    task :clear_statistics do
      ATTRIB_HASH.values.each do |collection|
        puts "---------- Dropping collection #{collection} ..."
        code = []
        code << 'use funnelcake;'
        code << "db.analytics.statistics.#{collection.pluralize}.drop();"
        send_to_mongo(code)
        puts "---------- DONE. moving on...."
      end
    end

    desc 'Remove robot visitors'
    task :clear_robot_visitors do
      robots = '/Googlebot|msnbot|Yahoo|Baidu|Teoma|robot|trada|scoutjet|crawl|tagoobot/i'
      code = []
      code << 'use funnelcake;'
      code << "db.analytics.visitors.remove({'events.user_agent': #{robots}});"
      send_to_mongo(code)
    end

  end

end