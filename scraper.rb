require 'nokogiri'
require 'httparty'
require 'byebug'
require 'open-uri'
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
  @ICONS = {
    'Colombia' => '🇨🇴 ',
    'Mundo' => '🌎',
    'Antioquia' => '🟢',
    'Economía' => '💰',
    'Tecnología' => '💻',
    'Salud' => '💉',
    'Cine' => '🎬',
    'Fútbol' => '⚽',
    'Cultura' => '🎨',
    'Educación' => '🎓',
    'Ciclismo' => '🚴',
    'Otros' => '🌐',
    'Noticias' => '📰',
    'Paz y derechos humanos' => '☮️ ',
    'Independiente Medellín' => '⚽',
    'Atlético Nacional' => '⚽',
    'Fútbol Colombiano' => '⚽',
    'Charlas de domingo' => '👄',
    'Política' => '🧑🏻‍⚖️',
    'Música' => '🎵',
    'Deportes' => '🏟️ ',
    'Tendencias' => '📈',
    'Farándula' => '👨🏻‍🎤',
    'Televisión' => '📺',
    nil => '📰'
  }

  if @noticias.nil?
    # puts 'No hay noticias disponibles'.colorize(:red)
    scraper
  else
    puts 'Escoja un titular:' unless @noticias.empty?
    puts
    # Hay noticias disponibles
    # byebug
    @noticias.each_with_index do |noticia, index|
      indexplusone = index + 1
      noticia[:categoria] = 'Noticias' if noticia[:categoria].empty?

      icon = @ICONS[noticia[:categoria]] || '📰'

      puts "#{format('%02d', indexplusone)}. #{icon} #{noticia[:categoria].colorize(:magenta)} | #{noticia[:titulo]}" unless noticia[:titulo].empty?
    end

    puts '0. Salir'.colorize(:red)
    puts 'f. Filtrar'.colorize(:red)

    print '> '.colorize(:yellow)

    @numero = STDIN.gets.chomp

    case @numero
    when ''
      puts 'Saliendo...'.colorize(:red)
      abort
    when '0'
      puts 'Saliendo...'.colorize(:red)
      abort
    when 'f'
      print 'Ingrese una expresión para filtrar los titulares o Enter para ver todos: '.colorize(:yellow)
      filter_char = STDIN.gets.chomp.to_s
      clear_screen
      print_header
      scraper(filter_char)
    end

    case @numero.to_i
    when 1..@noticias.size
      print_article(@numero.to_i)
    else
      puts "Opción '#{@numero}' inválida.".colorize(:red)
      print_menu
    end
  end
end

# Scrapes the news from the website's homepage
def scraper(filter_char = ARGV[0].to_s)
  # puts 'Cargando titulares...'.colorize(:yellow)

  @url = 'https://www.elcolombiano.com/'
  unparsed_page = HTTParty.get(@url)
  parsed_page = Nokogiri::HTML(unparsed_page.body)
  @noticias = []
  parsed_page.css('article.article').each do |article|
    title_node = article.at_css('div.div_iter_title span.priority-content') ||
                 article.at_css('h3.title__noticia__principal span.priority-content')
    next unless title_node
    title = title_node.text.strip
    href = article.at_css('div.div_iter_url')['data-urldestination'] rescue nil
    if href.nil? || href.empty?
      link = article.at_css('h3.title__noticia__principal a')
      href = link['href'] if link
    end
    next unless href
    url = href.start_with?('http') ? href : "#{@url.chomp('/')}#{href}"
    category_node = article.at_css('div.div_iter_categoria') ||
                    article.at_css('h4.categorie__noticia__principal a')
    category = category_node.text.strip rescue ''
    @noticias << { titulo: title, url: url, categoria: category }
  end

  # filter_char = ARGV[0].to_s

  @noticias = # selecciona las noticias que contengan el filter_char
    @noticias.uniq.select do |noticia|
      noticia[:titulo].include? filter_char
    end
  puts 'No hay noticias disponibles. Use otro filtro.'.colorize(:red) if @noticias.empty?

  print_menu
end

# Displays the article's content
def print_article(article_number)
  clear_screen

  print_header

  new_url = @noticias[article_number - 1][:url]

  unparsed_news = HTTParty.get(new_url)
  parsed_news = Nokogiri::HTML(unparsed_news.body)

  # Extract headline from article page
  title_node = parsed_news.at_css('h1[itemprop="headline"] span.priority-content') ||
               parsed_news.at_css('h1[itemprop="headline"]') ||
               parsed_news.at_css('h1.headline')
  titulo = title_node ? title_node.text.strip : ''
  # Extract lead paragraph
  lead_node = parsed_news.at_css('p.lead') || parsed_news.at_css('h2.lead')
  lead = lead_node ? lead_node.text.strip.colorize(:white) : ''
  cuerpo = parsed_news.css('div.paragraph p')
  autor = parsed_news.css('div.autor').text.strip.colorize(:cyan)
  img_src = parsed_news.at_css('figure.imagen-noticia img')&.[]('src')

  (titulo.size + 4).times { print '-'.black.on_white }
  puts
  puts "| #{titulo} |".black.on_white
  (titulo.size + 4).times { print '-'.black.on_white }
  puts
  puts
  puts lead
  puts
  if img_src && !img_src.empty?
    foto = img_src.start_with?('//') ? "https:#{img_src}" : img_src
    begin
      ascii = Image2ASCII.new(foto)
      ascii.generate(width: 80)
    rescue StandardError => e
      warn "[Error generating ASCII image: #{e.message}]"
    end
    puts foto
    puts
  end
  puts autor
  puts
  cuerpo.each do |parrafo|
    puts "  #{parrafo.text}"
    puts
  end

  puts
  puts "Fuente: #{new_url.colorize(:cyan)}"
  puts 'Presione Enter para regresar...'.colorize(:red)
  STDIN.gets

  start_program
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
