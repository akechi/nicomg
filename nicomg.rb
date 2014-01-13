require 'bundler'
Bundler.require

# config
config = YAML.load_file 'config.yml'
login_url = 'https://secure.nicovideo.jp/secure/login?site=niconico'

# agent initialize, connect
agent = Mechanize.new
agent.ssl_version = 'SSLv3'
agent.post(login_url, 'mail' => config['account']['email'], 'password' => config['account']['passwd'])

# get story list
title_id = ARGV[0] || 3770
stories_rss = agent.get("http://seiga.nicovideo.jp/rss/manga/#{title_id}")
xml = Nokogiri::XML stories_rss.body
stories = xml.xpath('rss/channel/item').map{|item|
  url = item.at('link').content
  {
    title: item.at('title').content,
    url: url,
    id: url.match(/mg(\d+)$/)[1]
  }
}

puts "Found #{stories.size} stories."

urls.map{|e|
  next unless /(mg(\d+))$/ =~ e
  mg = $1
  mg_num = $2
  FileUtils.mkdir_p(mg) unless FileTest.exist?(mg)
  manga = agent.get("http://seiga.nicovideo.jp/api/theme/data?theme_id=#{mg_num}")
  html = REXML::Document.new manga.body
  images = html.elements.each('response/image_list/image/source_url') do |e| e.text end
  images_url = images.map{|i|i.text.sub('l?','p?')}.sort
  images_url.each_with_index do |item,i| agent.get(item).save_as("./#{mg.to_s}/#{i+1}.jpg") end
}
