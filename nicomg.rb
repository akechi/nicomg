require 'mechanize'
require 'rexml/document'

agent = Mechanize.new
config = YAML.load_file 'config.yml'
agent.ssl_version = 'SSLv3'
secure_url = 'https://secure.nicovideo.jp/secure/login?site=niconico'
rss = agent.get("http://seiga.nicovideo.jp/rss/manga/#{ARGV[0]}")
html = REXML::Document.new rss.body
items = html.elements['rss/channel/item/link']
urls = items.map{|i|i.text}.sort
agent.post(secure_url, 'mail' => config['account']['email'], 'password' => config['account']['passwd'])
urls.map{|e|
  next unless /(mg(\d+))$/ =~ e
  FileUtils.mkdir_p($1.to_s) unless FileTest.exist?($1.to_s)
  manga = agent.get("http://seiga.nicovideo.jp/api/theme/data?theme_id=#{$2}")
  html = REXML::Document.new manga.body
  images = html.elements['response/image_list/image/source_url']
  images_url = images.map{|i|i.text.sub('l?','p?')}.sort
  images_url.each_with_index do |item,i| agent.get(item).save_as("./#{$1.to_s}/#{i+1}.jpg") end
}
