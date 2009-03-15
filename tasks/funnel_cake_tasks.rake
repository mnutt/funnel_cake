namespace :funnel_cake do
  desc 'Copy migration files into main app'
  task :setup do
    dest = "#{RAILS_ROOT}/db/migrate"
    src = Dir.glob(File.dirname(__FILE__) + "/../db/migrate/*.rb")
    puts "Copying migrations to #{dest}"
    FileUtils.cp(src, dest)

    dest = "#{RAILS_ROOT}/public"
    src = Dir.glob(File.dirname(__FILE__) + "/../public/*")
    puts "Copying assets to #{dest}"
    FileUtils.cp_r(src, dest)  
  end  
end