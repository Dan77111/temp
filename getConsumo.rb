require 'yaml'
require 'net/http'


def getMarche(macchine)
  source = Net::HTTP.get('www.ilsole24ore.com','/speciali/emissioni_auto/emissioni_auto_emissioni_tipologia_alfa_romeo_benzina.shtml')
  source = source[source.index("Selezione una marca")+144..-1]
  loop do
    marca = source[source.index(">")+1 .. source.index("<")-1]
    marca = marca.downcase
    marca.length.times do |i|
      marca[i] = "_" if marca[i] == " "
    end
    macchine[marca] = {}
    break if source.index("<option") == nil
    source = source[source.index("<option")+1..-1]
  end
  return macchine
end

def getTipiCarburante(macchine)
  macchine = getMarche(macchine)
  macchine.each do |marca,tipiCarburante|
    source = Net::HTTP.get('www.ilsole24ore.com','/speciali/emissioni_auto/emissioni_auto_emissioni_tipologia_'+marca+"_benzina.shtml") unless marca == "iveco" or marca == "mahindra"
    source = Net::HTTP.get('www.ilsole24ore.com','/speciali/emissioni_auto/emissioni_auto_emissioni_tipologia_'+marca+"_gasolio.shtml") if marca == "iveco" or marca == "mahindra"
    source = source[source.index("selectedLabel")+16..-1]
    loop do
      tipoCarburante = source[source.index(">")+1 .. source.index("<")-1]
      tipoCarburante = tipoCarburante.downcase
      tipoCarburante.length.times do |i|
        tipoCarburante[i] = "_" if tipoCarburante[i] == " "
      end
      tipiCarburante[tipoCarburante] = {}
      break if source.index("<a") > source.index("</div>")
      source = source[source.index("<a")+1 .. -1]
    end
  end
  return macchine
end

def getModelli(macchine)
  macchine = getTipiCarburante(macchine)
  macchine.each do |marca,tipiCarburante|
    tipiCarburante.each do |tipoCarburante, modelli|
      source = Net::HTTP.get('www.ilsole24ore.com','/speciali/emissioni_auto/emissioni_auto_emissioni_tipologia_'+marca+'_'+tipoCarburante+'.shtml')
      source = source[source.index("text-align:left;\" >")+19..-1]
      loop do
        modello = source[0 .. source.index("</div>")-1].strip.downcase
        modello = modello.sub(/&euml;/, "e")
        source = source[source.index("text-align:right;\">")+19..-1]
        cilindrata = (source[0 .. source.index("</div>")-1].strip.to_f+0.1).to_s[0..2].to_f
        3.times do
          source = source[source.index("</div>")+1..-1]
        end
        source = source[source.index("text-align:left;\">")+18..-1]
        consumo = source[0..source.index("<")-1].strip.to_f
        if modelli[modello] != nil
          modelli[modello][cilindrata] = !modelli[modello].key?(cilindrata) ? [consumo, 1] : [modelli[modello][cilindrata][0]+consumo, modelli[modello][cilindrata][1]+1]
        else
          modelli[modello] = {cilindrata=>[consumo, 1]}
        end
        break if source.index("text-align:left;\" >") == nil
        source = source[source.index("text-align:left;\" >")+19..-1]
      end
      modelli.each do |modello, datiModello|
        datiModello.each do |cilindrata, dati|
          dati[0] = (100/dati[0]/dati[1]).round(1)
        end
      end
    end
  end
end


def getConsumo()
  File.open('consumi.yaml', 'w') { |fo| fo.puts getModelli(Hash.new).to_yaml }
end

#macchine = { marca=>{ benzina=>{ macchina=>{ "cilindrata" => [consumo, nModelliCilindrataUguale], ... },... } gasolio=>{ ... }, ... }, ... }
