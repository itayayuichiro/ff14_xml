require 'json'
require 'open-uri'
require 'nokogiri'

# JSONファイルを読み込む関数
def read_json_file(file_path)
  if File.exist?(file_path)
    JSON.parse(File.read(file_path), symbolize_names: true)
  else
    []
  end
end

# JSONファイルに書き込む関数
def write_json_file(file_path, data)
  File.write(file_path, JSON.pretty_generate(data))
end

# サイトから情報を取得する関数
def umatori_fetch_site_info(url)
  # HTMLをパース
  doc = Nokogiri::HTML(URI.open(url))

  articles = doc.css('.boxwrap').map do |li|
    title = li.at_css('.boxentrytitle')
    hash = {
      title: title.text,
      link: title[:href],
      date: DateTime.strptime(li.at_css('.postinfo').text, "%Y年%m月%d日%H:%M"),
      category: li.at_css('.catlink').text,
      site: '馬鳥速報'
    }
  end
  articles
end

# サイトから情報を取得する関数
def hikasen_fetch_site_info(url)
  # HTMLをパース
  doc = Nokogiri::HTML(URI.open(url))

  articles = doc.css('article').map do |art|
    title = art.at_css('.entry_title_link')
    hash = {
      title: title.text.strip,
      link: title[:href],
      date: DateTime.strptime(art.at_css('.entry_date').text.strip.gsub(" ", ""), "%Y年%m月%d日%H:%M"),
      category: art.at_css('.entry_category_name').text.strip,
      site: 'FF14ひかせん速報'
    }
  end
  articles
end

# サイトから情報を取得する関数
def sokuho_fetch_site_info(url)
  # HTMLをパース
  doc = Nokogiri::HTML(URI.open(url))

  articles = doc.css('.article-header').map do |art|
    title = art.at_css('.article-title a')
    hash = {
      title: title.text.strip,
      link: title[:href],
      date: art.at_css('.article-header-date time')[:datetime],
      category: art.at_css('.article-category1')&.text&.strip || "",
      site: 'FF14速報'
    }
  end
  articles
end

def umatori
  top_url = 'http://blog.livedoor.jp/umadori0726/'
  articles = umatori_fetch_site_info(top_url)
  10.times do |i|
    top_url = 'http://blog.livedoor.jp/umadori0726/?p=' + (i+2).to_s
    articles = articles + umatori_fetch_site_info(top_url)
    sleep 0.5
  end
  articles
end

def hikasen
  top_url = 'https://ff14hikasensokuhou.com/'
  articles = hikasen_fetch_site_info(top_url)
  10.times do |i|
    top_url = "https://ff14hikasensokuhou.com/page-#{(i+2).to_s}.html"
    articles = articles + hikasen_fetch_site_info(top_url)
    sleep 0.5
  end
  articles
end

def sokuho
  top_url = 'https://ff14net.2chblog.jp/'
  articles = sokuho_fetch_site_info(top_url)
  10.times do |i|
    top_url = "https://ff14net.2chblog.jp/?p=#{(i+2).to_s}"
    articles = articles + sokuho_fetch_site_info(top_url)
    sleep 0.5
  end
  articles
end


# メイン処理
def main
  articles = []
  articles = articles + umatori
  articles = articles + hikasen
  articles = articles + sokuho

  file_path = 'site_info.json'

  # 既存のJSONデータを読み込む
  existing_data = read_json_file(file_path)

  # 重複チェックと追加
  articles.each do |article|
    unless existing_data.any? { |item| item[:link] == article[:link] }
      existing_data.unshift(article)
    end
  end

  existing_data = existing_data.sort_by { |hash| DateTime.parse(hash[:date]) }.reverse

  # 更新されたデータをJSONファイルに書き込む
  write_json_file(file_path, existing_data)

  puts "サイト情報がJSONファイルに追記されました。"
end


main