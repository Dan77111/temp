require 'open-uri'
require 'yaml'

marche = open("http://www.auto-data.net/en/?f=brands").read

macchine = Hash.new

marche = marche[marche.index('<div class="markite">')+22 .. marche.index('The most popular cars')-1]

def parseMarche(marche, macchine)
  str = marche
  nome = str[ str.index(">")+1 .. str.index("<")-1 ]
  id = str[0..130].scan(/\d/).join('').to_i
  macchine[nome] = { "id" => id } unless nome == ""
  str = str[str.index("<")+1 .. -1]
  return parseMarche(str, macchine) unless str.length < 118
  return macchine
end

macchine = parseMarche(marche, macchine)

def parseTipi(tipi, macchine)
  str = tipi
  return {} if str == ""
  id = str[0..58].scan(/\d/).join('').to_i
  str = str[str.index("<span>")+6 .. -1]
  nome = str[0 .. str.index("<")-1 ]
  macchine[nome] = { "id" => id } unless nome == ""
  str = str[str.index("<a class")+1 .. -1] unless str.length < 329
  return parseTipi(str, macchine) unless str.length < 329
  return macchine
end

macchine.each do |key, value|
  id = value["id"]
  tipi = open("http://www.auto-data.net/en/?f=showModel&marki_id="+value["id"].to_s).read
  tipi = tipi[tipi.index('<div class="markite">')+34 .. tipi.index('incarleft')-27]
  value = parseTipi(tipi,value)
  value["id"] = id
end

def parseModelli(modelli, macchine)
  str = modelli
  return {} if str == ""
  id = str[0..58].scan(/\d/).join('').to_i
  str = str[str.index("<span>")+6 .. -1]
  nome = str[0 .. str.index("<")-1 ]
  macchine[nome] = { "id" => id } unless nome == ""
  str = str[str.index("<a class")+1 .. -1] unless str.length < 329
  return parseTipi(str, macchine) unless str.length < 329
  return macchine
end

macchine.each do |key, value|
  value.each do |valueKey, valueValue|

  end
end

File.open('consumes.yaml', 'w') { |fo| fo.puts macchine.to_yaml }
