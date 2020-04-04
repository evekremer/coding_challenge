require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.verbose = false
  t.warning = true
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test

task :purge_expired_keys do
    #Post.where('expired_at <= ?', Time.now).destroy_all
end