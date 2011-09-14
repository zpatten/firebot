require 'rubygems'
require 'hpricot'

require 'net/https'
require 'uri'
require 'pp'

MY_USER_ID = 991971

BAD_EVAL = [/`(.*)`/, /exec/, /system/]

receive do |session, event|
  #next if event.user_id == MY_USER_ID

  # someone wants to eval ruby code
  if event.text? && event.body.strip =~ /^!eval (.*)$/
    ev = $1
    if BAD_EVAL.any?{|e| ev =~ e}
      event.room.say! "Tsk! Tsk!"
    else
      event.room.paste! "Eval result:\n" + eval(ev).to_s
    end
  end

  # someone wants to search google
  if event.text? && event.body.strip =~ /^!google (.*)$/
    event.room.say! search_google($1)
  end

  # someone posted a url; lets do some homework on it
  if event.text? && event.body.strip =~ /^http(|s):\/\/(.*)$/
    event.room.say! ">> #{tiny_url("http#{$1}://#{$2}")} <<  [ #{page_title("http#{$1}://#{$2}", ($1 == 's'))} ]"
  end

  # display some hopefully helpful text
  if event.text? && event.body.strip =~ /^!help$/
    event.room.say! "Hello I'm your friendly Campfire bot! -- I currently accept these commands: !help, !google, !eval"
  end
end

def search_google(query)
  html = Net::HTTP.get(URI.parse("http://www.google.com/search?q=#{CGI.escape(query)}"))
  doc = Hpricot(html)
  a = doc.search("//h3/a").first
  title = page_title(CGI.unescape(a.attributes['href'].strip)) #CGI.unescape(a.inner_html.strip.gsub(/<(.*?)>/, ''))
  href = tiny_url(CGI.unescape(a.attributes['href'].strip))
  ">> #{href} <<  [ #{title} ]"
end

def tiny_url(url)
  html = Net::HTTP.get(URI.parse("http://tinyurl.com/create.php?url=#{CGI.escape(url)}"))
  doc = Hpricot(html)
  a = doc.search("//blockquote/small/a").first
  CGI.unescape(a.attributes['href'].strip)
end

def page_title(url,ssl=false)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  if ssl
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  html = response.body

  doc = Hpricot(html)
  a = doc.search("//head/title").first
  (a.inner_html.nil? ? "No Title Available" : CGI.unescape(a.inner_html.gsub(/<(.*?)>/, '').strip))
end
