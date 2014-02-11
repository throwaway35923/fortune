#!/usr/bin/env ruby

require 'json'
require 'open3'
require 'sinatra'

module Fortune
  class CommandFailed < Exception; end

  # not using Sinatra helper because this is simpler to stub
  def self.command
    'fortune'
  end
end

get '/fortune/' do
  content_type(:json)

  flags = []

  case params[:long]
  when '0'
    flags << '-s'
  when '1'
    flags << '-l'
  end

  case params[:dirty]
  when '1'
    flags << '-o'
  when '0'
    # default, no flag needed
  else
    flags << '-a'
  end

  command = ([Fortune.command] + flags).join(' ')
  stdout, stderr, status = Open3.capture3(command)

  raise Fortune::CommandFailed.new(stderr) unless status.exitstatus == 0

  {:text => stdout}.to_json
end

