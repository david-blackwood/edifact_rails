# frozen_string_literal: true

require "rake"
require "rake/testtask"
require "rubocop/rake_task"

RuboCop::RakeTask.new do |task|
  task.requires << "rubocop-performance"
  task.requires << "rubocop-rspec"
end

Rake::TestTask.new do |task|
  task.libs << "test"
end

desc "Run tests"
task default: :test
