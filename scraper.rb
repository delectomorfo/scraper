require 'nokogiri'
require 'httparty'
require 'byebug'
require 'image2ascii'
require 'colorize'

# Prints out the newspaper's name
def print_header
  puts '  ______ _         _____ ____  _      ____  __  __ ____ _____          _   _  ____  '
  puts ' |  ____| |       / ____/ __ \| |    / __ \|  \/  |  _ \_   _|   /\   | \ | |/ __ \ '
  puts ' | |__  | |      | |   | |  | | |   | |  | | \  / | |_) || |    /  \  |  \| | |  | |'
  puts ' |  __| | |      | |   | |  | | |   | |  | | |\/| |  _ < | |   / /\ \ | . ` | |  | |'
  puts ' | |____| |____  | |___| |__| | |___| |__| | |  | | |_) || |_ / ____ \| |\  | |__| |'
  puts ' |______|______|  \_____\____/|______\____/|_|  |_|____/_____/_/    \_\_| \_|\____/ '
  puts
end

# Displays a menu of news stories
def print_menu
  if @noticias.nil? 
    # puts 'No hay noticias disponibles'.colorize(:red)
    scraper
  else
    puts 'Escoja un titular:'
    puts
    # Hay noticias disponibles
    @noticias.each_with_index do |noticia, index|
      noticia[:categoria] = 'Noticias' if noticia[:categoria].empty?
  
      puts "#{index + 1}. #{icon(noticia[:categoria])} #{noticia[:categoria].colorize(:magenta)} | #{noticia[:titulo]}"
      # byebug
    end
  
    puts '0. Salir'.colorize(:red)
    print '> '.colorize(:yellow)
  
    @numero = STDIN.gets.chomp.to_i
  
    abort if @numero.zero?
  
    print_article(:numero)
  end
end

# Scrapes the news from the website's homepage
def scraper
  # puts 'Cargando titulares...'.colorize(:yellow)

  @url = 'https://www.elcolombiano.com/'
  unparsed_page = HTTParty.get(@url)
  parsed_page = Nokogiri::HTML(unparsed_page.body)
  @noticias = []
  titulares = parsed_page.css('article.article') # selecciona todos los artículos de la página
  
  titulares.each do |titular|
    @noticia = {
      titulo: titular.css('h3').text.strip,
      url: @url.to_s + titular.css('h3 a').attribute('href').to_s,
      categoria: titular.css('div.categoria-noticia a').text.strip
    }
    @noticias << @noticia # ponemos cada noticia en el array
  end

  filter_char = ARGV[0].to_s 

  @noticias = @noticias.uniq.select { |noticia| noticia[:titulo].include? filter_char } # selecciona las noticias que contengan el filter_char
  print_menu
end

# Displays the article's content
def print_article(article_number)
  clear_screen

  print_header

  new_url = @noticias[@numero - 1][:url]

  unparsed_news = HTTParty.get(new_url)
  parsed_news = Nokogiri::HTML(unparsed_news.body)

  titulo = parsed_news.css('h1.headline').text
  lead = parsed_news.css('h2.lead').text.colorize(:white)
  cuerpo = parsed_news.css('div.paragraph p')
  autor = parsed_news.css('div.autor').text.strip.colorize(:cyan)
  foto = "https:#{parsed_news.css('figure.imagen-noticia img').attribute('src')}"

  (titulo.size + 4).times { print '-'.black.on_white }
  puts
  puts "| #{titulo} |".black.on_white
  (titulo.size + 4).times { print '-'.black.on_white }
  puts
  puts
  puts lead
  puts
  ascii = Image2ASCII.new(foto)
  ascii.generate(width: 80)
  puts foto
  puts
  puts autor
  puts
  cuerpo.each do |parrafo|
    puts "  #{parrafo.text}"
    puts
  end

  puts
  puts 'Presione Enter para regresar...'.colorize(:red)
  STDIN.gets

  start_program
end

# Prints out the menu's icons
def icon(category)
  case category
  when 'Colombia'
    '🇨🇴 '
  when 'Mundo'
    '🌎'
  when 'Antioquia'
    '🟢'
  when 'Economía'
    '💰'
  when 'Tecnología'
    '💻'
  when 'Salud'
    '💉'
  when 'Cine'
    '🎬'
  when 'Fútbol'
    '⚽'
  when 'Cultura'
    '🎨'
  when 'Educación'
    '🎓'
  when 'Ciclismo'
    '🚴'
  when 'Otros'
    '🌐'
  when 'Paz y derechos humanos'
    '☮️ '
  when 'Independiente Medellín'
    '⚽'
  when 'Política'
    '🤵🏻'
  when 'Música'
    '🎵'
  when 'Deportes'
    '🏟️ '
  when 'Tendencias'
    '📈'
  else
    '📰'
  end
end

# Clears the screen
def clear_screen
  if RUBY_PLATFORM =~ /win32|win64|\.NET|windows|cygwin|mingw32/i
    system('cls')
  else
    system('clear')
  end
end

# Starts the program
def start_program
  clear_screen
  print_header
  print_menu
end

start_program

# titulares = parsed_page.css('span.priority-content')
# titulares.count
# primero = titulares.first
# titulares[n].text
