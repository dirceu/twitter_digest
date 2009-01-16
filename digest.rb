# Simple twitter digest. This is experimental code, no warranty or guarantee it will work.
# Author: Dirceu Pereira Tiegs (http://dirceu.info).

pwd = File.expand_path('.') + '/'

require pwd + 'twitter'
require 'rss/maker'

class Twitter
  def last_tweets
    filename = pwd + 'last_id.txt'
    begin
      last_id = open(filename, 'r') { |f| f.read.to_i }
      tweets = self.timeline(:friends, :query => {:since_id => last_id})
    rescue Errno::ENOENT
      puts "OMG, error!!!11oneeleven! '#{filename}' not found."
      tweets = self.timeline
    end
    if !tweets.empty?
      last_id = tweets[0]['id']
      open(filename, 'w') { |f| f.write(last_id) }
    end
    tweets
  end
end

config = YAML::load(open(pwd + 'config.yml'))['config']
twitter = Twitter.new(config['email'], config['password'])
tweets = twitter.last_tweets
if tweets.empty?
  Process.exit
end

content = RSS::Maker.make('2.0') do |m|
  m.channel.title = "Twitter Digest"
  m.channel.link = "http://twitter.com/home"
  m.channel.description = "A twitter digest created by Dirceu Pereira Tiegs (http://dirceu.info)."
  m.items.do_sort = true

  i = m.items.new_item
  i.title = "Tweet digest"
  i.description = "<table border='0'>"
  tweets.each do |t|
    name = t['user']['screen_name']
    link = "http://twitter.com/#{name}/status/#{t['id']}"
    i.description += "<tr><td><img src='#{t['profile_image_url']}' alt='' width='48' height='48' /></td><td><a href='#{link}' title='#{t['user']['name']}'>#{name}</a>: #{t['text']}</td></tr>"
  end
  i.description += "</table>"
  i.link = "http://twitter.com/home"
  i.date = Time.now
end

open(pwd + 'twitter.xml', 'w') { |f| f.write(content) }
