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
  mg = $1
  mg_num = $2
  FileUtils.mkdir_p(mg) unless FileTest.exist?(mg)
  manga = agent.get("http://seiga.nicovideo.jp/api/theme/data?theme_id=#{mg_num}")
  html = REXML::Document.new manga.body
  images = html.elements['response/image_list/image/source_url']
  images_url = images.map{|i|i.text.sub('l?','p?')}.sort
  images_url.each_with_index do |item,i| agent.get(item).save_as("./#{mg.to_s}/#{i+1}.jpg") end
}
