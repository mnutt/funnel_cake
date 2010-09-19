namespace :funnel_cake do
  desc 'Copy assets into main app'
  task :copy_assets => :environment do
    dest = "#{Rails.root.to_s}/public"
    src = Dir.glob(File.dirname(__FILE__) + "/../public/*")
    puts "Copying assets to #{dest}"
    FileUtils.cp_r(src, dest)
  end

  desc 'Generate xdot'
  task :generate_xdot => :environment do
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

    desc 'Run map-reduce aggregations on existing visitor data to build statistics collections'
    task :build_statistics => :environment do
      ATTRIB_HASH.each do |attrib, collection|
        puts "---------- Building collection #{collection} from events[0].#{attrib}..."

        map = "function(){ emit( (this.events && this.events[0] && this.events[0].#{attrib}) ? this.events[0].#{attrib} : null, {count: 1}) };"
        reduce = "function( key , values ){  var total = 0; for ( var i=0; i<values.length; i++) { total += values[i].count; } return { count : total }; };"
        MongoMapper.database.collection("analytics.visitors").map_reduce map, reduce,
          :out=>"analytics.statistics.#{collection.pluralize}",
          :query=>{:created_at=>{:'$gt'=>1.month.ago.utc}}

        MongoMapper.database.create_index "analytics.statistics.#{collection.pluralize}", ['value.count', Mongo::DESCENDING]

        puts "---------- DONE. moving on...."
      end
    end

    desc 'Drop existing visitor statistics collections'
    task :clear_statistics => :environment do
      ATTRIB_HASH.values.each do |collection|
        puts "---------- Dropping collection #{collection} ..."
        MongoMapper.database.drop_collection "analytics.statistics.#{collection.pluralize}"
        puts "---------- DONE. moving on...."
      end
    end

    desc 'Remove robot visitors'
    task :clear_robot_visitors => :environment do
      robots = /Googlebot|msnbot|Yahoo|Baidu|Teoma|robot|trada|scoutjet|crawl|tagoobot/i
      MongoMapper.database.collection("analytics.visitors").remove 'events.user_agent'=>robots
    end

  end

end
