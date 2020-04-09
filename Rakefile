require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "test/unit/*_test.rb"
end

task default: :test

task :purge_expired_keys do
    #Post.where('expired_at <= ?', Time.now).destroy_all
end