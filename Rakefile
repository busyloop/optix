#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rspec/core/rake_task'

task :default => :test

RSpec::Core::RakeTask.new("test:spec") do |t|
    t.pattern = 'spec/*_spec.rb'
    t.rcov = false
    #t.rspec_opts = '-b -c -f progress --tag ~benchmark'
    t.rspec_opts = '--fail-fast -b -c -f documentation --tag ~benchmark'
end

RSpec::Core::RakeTask.new("test:benchmark") do |t|
    t.pattern = 'spec/*.rb'
    t.rcov = false
    t.rspec_opts = '-b -c -f documentation --tag benchmark'
end


namespace :test do
  task :coverage do
    #require 'cover_me'
    #CoverMe.complete!
  end
end

desc 'Run full test suite'
task :test => [ 'test:spec', 'test:coverage' ]
