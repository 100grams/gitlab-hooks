require 'rubygems'
require 'sinatra'
require 'json'
require 'net/http'
require 'net/https'
require 'uri'
require 'asana'
require 'hipchat'
require './env' if File.exists?('env.rb')

set :protection, :except => [:http_origin]

# use Rack::Auth::Basic do |username, password|
#   [username, password] == [ENV['username'], ENV['password']]
# end

post '/' do
  json_string = request.body.read.to_s
  puts json_string
  payload = JSON.parse(json_string)
  
  user = payload['user_name']
  branch = payload['ref'].split('/').last
  
  rep = payload['repository']['url'].split('/').last(2).join('/')
  push_msg = user + " pushed to branch " + branch + " of " + rep
  
  Asana.configure do |client|
    client.api_key = ENV['auth_token']
  end
  
  @hipchat = HipChat::Client.new(ENV['hipchat_token'])
  
  payload['commits'].each do |commit|
    check_commit(commit, push_msg)
  end
  
  "Posted to asana!!"
end

def check_commit(commit, push_msg)
  message = " (" + commit['url'] + ")\n- " + commit['message']
  @hipchat[ENV['room_name']].send('GitLab', "#{push_msg} #{message}")

  task_list = []
  close_list = []
  message.split("\n").each do |line|
    task_list.concat( line.scan(/#(\d+)/) )
    close_list.concat( line.scan(/(fix\w*)\W*#(\d+)/i) )
  end
  
  # post commit to every taskid found
  task_list.each do |taskid|
    task = Asana::Task.find(taskid[0])
    task.create_story({'text' => "#{push_msg} + #{message}"})
  end

  # close all tasks that had fixed #:id in them
  close_list.each do |taskid|
    task = Asana::Task.find(taskid.last)
    task.modify(:completed => true)
  end
end

