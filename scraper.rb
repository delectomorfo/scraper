require 'nokogiri'
require 'httparty'
require 'byebug'
require 'image2ascii'
require 'colorize'

def scraper
  clear_screen

  puts '  ______ _         _____ ____  _      ____  __  __ ____ _____          _   _  ____  '
  puts ' |  ____| |       / ____/ __ \| |    / __ \|  \/  |  _ \_   _|   /\   | \ | |/ __ \ '
  puts ' | |__  | |      | |   | |  | | |   | |  | | \  / | |_) || |    /  \  |  \| | |  | |'
  puts ' |  __| | |      | |   | |  | | |   | |  | | |\/| |  _ < | |   / /\ \ | . ` | |  | |'
  puts ' | |____| |____  | |___| |__| | |___| |__| | |  | | |_) || |_ / ____ \| |\  | |__| |'
  puts ' |______|______|  \_____\____/|______\____/|_|  |_|____/_____/_/    \_\_| \_|\____/ '
  puts
  puts 'Escoja un titular:'
  puts
  url = 'https://www.elcolombiano.com/'
  unparsed_page = HTTParty.get(url)
  parsed_page = Nokogiri::HTML(unparsed_page.body)
  noticias = []
  titulares = parsed_page.css('article.article') # selecciona todos los artículos de la página

  titulares.each do |titular|
    noticia = {
      titulo: titular.css('h3').text.strip,
      url: url + titular.css('h3 a').attribute('href').to_s,
      categoria: titular.css('div.categoria-noticia a').text
    }
    noticias << noticia # ponemos cada noticia en el array
  end

  noticias = noticias.uniq.select { |noticia| noticia[:titulo].include? '¿' } # selecciona las noticias que contengan ¿

  noticias.each_with_index do |noticia, index|
    puts "#{index + 1}. #{noticia[:categoria].colorize(:magenta)} ➡️  #{noticia[:titulo]}"
  end

  puts '0. Salir'.colorize(:red)
  print '> '.colorize(:yellow)
  numero = gets.chomp.to_i

  abort if numero.zero?

  clear_screen

  new_url = noticias[numero - 1][:url]

  unparsed_news = HTTParty.get(new_url)
  parsed_news = Nokogiri::HTML(unparsed_news.body)

  titulo = parsed_news.css('h1.headline').text
  lead = parsed_news.css('h2.lead').text
  cuerpo = parsed_news.css('div.paragraph p')
  foto = 'https:' + parsed_news.css('figure.imagen-noticia img').attribute('src').to_s

  puts
  puts titulo.black.on_white
  titulo.size.times { print '~'.colorize(:yellow) }
  puts
  puts lead
  puts
  ascii = Image2ASCII.new(foto)
  ascii.generate(width: 100)
  puts
  cuerpo.each do |parrafo|
    puts parrafo.text
    puts
  end

  puts
  puts 'Presione Enter para regresar...'.colorize(:red)
  gets

  scraper
end

def clear_screen
  if RUBY_PLATFORM =~ /win32|win64|\.NET|windows|cygwin|mingw32/i
    system('cls')
  else
    system('clear')
  end
end

scraper

# titulares = parsed_page.css('span.priority-content')
# titulares.count
# primero = titulares.first
# titulares[n].text
