require 'yaml'
require 'net/http'


source = Net::HTTP.get('osservaprezzi.sviluppoeconomico.gov.it', '/index.php?option=com_content&view=article&id=22&Itemid=138')

stringaDati = source[ (16+source.index("var gridData")) .. ( (source[source.index("gridData") .. -1].index("\n") - 1)+ source.index("gridData"))].to_s.force_encoding("UTF-8")

stringaDati.length.times do |i|
  if stringaDati[i] == "à"
    stringaDati[i] = "a"
  elsif stringaDati[i] == "è"
    stringaDati[i] = "e"
  elsif stringaDati[i] == "é"
    stringaDati[i] = "e"
  elsif stringaDati[i] == "ò"
    stringaDati[i] = "o"
  elsif stringaDati[i] == "ù"
    stringaDati[i] = "u"
  end
end
dati = Hash.new

stringaDati.split("},{").each do |element|
  element = element[1..-1] if element.start_with? '{'
  element = element[0..-2] if element.end_with? '}'
  nome = element[ (10 + element.index("prodotto:")) .. (element.rindex(" ")) ].rstrip
  qta = element[element.index('(')+1 .. element.index(')')-4].to_i
  min = element[ (8 + element.index("minimo:")) .. 12 + element.index("minimo:")][0..3].to_f
  med = element[ (7 + element.index("medio:")) .. 11 + element.index("medio:")][0..3].to_f
  max = element[ (9 + element.index("massimo:")) .. 13 + element.index("massimo:")][0..3].to_f
  dati[nome] = {:qta => qta, :min => min, :med => med, :max => max}
end

File.open('prices.yaml', 'w') { |fo| fo.puts dati.to_yaml }


#fai hash con il file
dati = YAML.load_file('prices.yaml')
