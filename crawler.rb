require 'json'
require 'open-uri'
require 'nokogiri'

# サイトから情報を取得する関数
def fetch_site_info(url)
  # HTMLをパース
  doc = Nokogiri::HTML(URI.open(url))

  articles = doc.css('.boxwrap').map do |li|
    title = li.at_css('.boxentrytitle')
    hash = {
      title: title.text,
      link: title[:href],
      date: li.at_css('.postinfo').text,
      category: li.at_css('.catlink').text,
    }
  end
  articles
end

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

# メイン処理
def main
  top_url = 'http://blog.livedoor.jp/umadori0726/'
  articles = fetch_site_info(top_url)
  2.times do |i|
    top_url = 'http://blog.livedoor.jp/umadori0726/?p=' + (i+2).to_s
    articles = articles + fetch_site_info(top_url)
    sleep 0.5
  end

  file_path = 'site_info.json'

  # 既存のJSONデータを読み込む
  existing_data = read_json_file(file_path)

  # 重複チェックと追加
  articles.each do |article|
    unless existing_data.any? { |item| item[:link] == article[:link] }
      existing_data.unshift(article)
    end
  end

  # 更新されたデータをJSONファイルに書き込む
  write_json_file(file_path, existing_data)

  puts "サイト情報がJSONファイルに追記されました。"
end

main
