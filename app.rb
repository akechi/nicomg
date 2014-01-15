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

# Create Manga title dir
title = xml.at('rss/channel/title').content.sub(' - ニコニコ静画（マンガ）', '')
cache_title_path = "./caches/#{title}"
archive_title_path = "./archives/#{title}"
FileUtils.mkdir_p cache_title_path unless FileTest.exists? cache_title_path
FileUtils.mkdir_p archive_title_path unless FileTest.exists? archive_title_path

# Get all stories
stories = xml.xpath('rss/channel/item').map{|item|
  url = item.at('link').content
  {
    title: item.at('title').content,
    url: url,
    id: url.match(/mg(\d+)$/)[1]
  }
}.reverse

puts "Found #{stories.size} stories."

stories.each do |story, i|
  puts "\nFetch #{story[:title]}"

  story_path = "#{cache_title_path}/#{story[:title]}"
  FileUtils.mkdir_p story_path unless FileTest.exists? story_path

  xml = Nokogiri::XML agent.get("http://seiga.nicovideo.jp/api/theme/data?theme_id=#{story[:id]}").body
  pages = xml.xpath('response/image_list/image/source_url').map{|url|
    {
      url: url.content.sub(/l\?\d*$/, 'p?'),
      id: url.content.match(/(\d+)l\?\d*$/)[1]
    }
  }

  # Fetch pages
  Zip::File.open("#{archive_title_path}/#{story[:title]}.zip", Zip::File::CREATE) do |zip|
    zip.dir.mkdir(story[:title])
    pages.each.with_progress('Fetch pages') do |page|
      page_path = "#{story_path}/#{page[:id]}.jpg"
      unless File.exists? page_path
        agent.get(page[:url]).save_as page_path
      end
      zip.file.open("#{story[:title]}/#{File.basename(page_path)}", "w"){|f| f.puts open(page_path).read}
    end
  end
end

# TODO:zip them
