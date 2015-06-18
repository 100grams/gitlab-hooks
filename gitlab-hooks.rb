require 'rubygems'
require 'sinatra'
require 'eventmachine' # lol node wat
require 'json'
require 'hipchat'
require './env' if File.exists?('env.rb')
require 'asana'

set :protection, :except => [:http_origin]

# use Rack::Auth::Basic do |username, password|
#   [username, password] == [ENV['username'], ENV['password']]
# end

HIPCHAT_COLORS = %w(yellow green purple gray) # red is reserved for errors
DEFAULT_COLOR = 'yellow'

post '/' do
  EventMachine.run do
    json_string = request.body.read.to_s
    puts json_string
    payload = JSON.parse(json_string)

    user = payload['user_name']
    branch = payload['ref'].split('/').last

    rep = payload['repository']['url'].split('/').last(2).join('/')
    push_msg = user + " pushed to branch " + branch + " of " + rep

    api_token = ENV['asana_api_token']
    unless api_token
      abort "Run this program with the env var ASANA_API_TOKEN.\n"  \
        "Go to http://app.asana.com/-/account_api to see your API token."
    end

    @client = Asana::Client.new do |c|
      c.authentication :api_token, api_token
    end

    @hipchat = HipChat::Client.new(ENV['hipchat_token'])
    @msg_color = params['color'].nil? || !HIPCHAT_COLORS.include?(params['color']) ? DEFAULT_COLOR : params['color']
    room = params['room']

    EventMachine.defer do
      payload['commits'].each do |commit|
        message = " (" + commit['url'] + ")\n- #{commit['message']}"
        check_commit(message, push_msg)
        post_hipchat_message(push_msg + message, room)
      end
    end
  end
  "BOOM! EvenMachine handled it!"
end

def check_commit(message, push_msg)
  task_list = []
  close_list = []

  message.split("\n").each do |line|
    task_list.concat(line.scan(/#(\d+)/)) # look for a task ID
    close_list.concat(line.scan(/(fix\w*)\W*#(\d+)/i)) # look for a word starting with 'fix' followed by a task ID
  end

  # post commit to every taskid found
  task_list.each do |taskid|
    task = @client.tasks.find_by_id(taskid[0])
    task.add_comment(text:"#{push_msg} #{message}")
  end

  # close all tasks that had 'fix(ed/es/ing) #:id' in them
  close_list.each do |taskid|
    task = @client.tasks.find_by_id(taskid.last)
    task.update(:completed => true)
  end
end

def post_hipchat_message(message, room)
  @hipchat[room].send('GitLab Bot', message, :notify => true, :color => @msg_color)
end

