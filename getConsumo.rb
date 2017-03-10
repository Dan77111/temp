require 'yaml'
require 'net/http'

#Aggiunge a un hash le marche delle macchine presenti sul sito: hash = { marca1 => {}, marca2 => {}, ecc.}
def getMarche( macchine )
  #scarica l'HTML e taglia la prima parte perchè non serve
  source = Net::HTTP.get( 'www.ilsole24ore.com', '/speciali/emissioni_auto/emissioni_auto_emissioni_tipologia_alfa_romeo_benzina.shtml' )
  source = source[ source.index( "Selezione una marca" ) + 144 .. - 1 ]
  #ricerca tutte le marche e le aggiunge all'hash
  loop do
    #trova le marche
    marca = source[ source.index( ">" ) + 1 .. source.index( "<" ) - 1 ].downcase
    #toglie gli spazi e li sostituisce con _ perchè servono per gli url
    marca.length.times do |i|
      marca[ i ] = "_" if marca[ i ] == " "
    end
    #aggiunge le marche nell'hash
    macchine[ marca ] = {}
    #esce se è l'ultima
    break if source.index( "<option" ) == nil
    #se non è l'ultima taglia il pezzo già usato
    source = source[ source.index( "<option" ) + 1 .. - 1 ]
  end
  return macchine
end

#Invoca getMarche e poi aggiunge all'hash quali tipi di carburante possono avere le macchine di ogni marca
#hash = { marca1 => {tipoCarburante1=>{}, ecc.}, ecc.}
def getTipiCarburante( macchine )
  #invoca getMarche
  macchine = getMarche( macchine )
  #itera attraverso l'hash con la marca come "marca" e {} come tipiCarburante
  macchine.each do |marca, tipiCarburante|
    #Ottieni la pagina da ispezionare
    #Tutte le marche hanno almeno un'auto a benzina trane Iveco e Mahindra, quindi abbiamo usato la pagina
    #delle auto a benzina per tutte tranne quelle 2
    source = Net::HTTP.get( 'www.ilsole24ore.com', '/speciali/emissioni_auto/emissioni_auto_emissioni_tipologia_' + marca + "_benzina.shtml") unless marca == "iveco" or marca == "mahindra"
    source = Net::HTTP.get( 'www.ilsole24ore.com', '/speciali/emissioni_auto/emissioni_auto_emissioni_tipologia_' + marca + "_gasolio.shtml") if marca == "iveco" or marca == "mahindra"
    #Taglia la parte iniziale del file che non serve
    source = source[ source.index( "selectedLabel" ) + 16 .. -1 ]
    #Trova i tipi di carburante e li aggiunge
    loop do
      #Trova il tipo di carburante
      tipoCarburante = source[ source.index( ">" ) + 1 .. source.index( "<" ) - 1 ].downcase
      #sostituisce gli spazi con _ per usare la chiave dell'hash direttamente come parte dell'url
      tipoCarburante.length.times do |i|
        tipoCarburante[ i ] = "_" if tipoCarburante[ i ] == " "
      end
      #aggiunge all'hash
      tipiCarburante[ tipoCarburante ] = {}
      #esce se è l'ultimo
      break if source.index( "<a" ) > source.index( "</div>" )
      #se non è l'ultima taglia il pezzo già usato
      source = source[ source.index( "<a" ) + 1 .. - 1 ]
    end
  end
  return macchine
end

#Invoca getTipiCarburante e poi aggiunge all'hash quali tipi di carburante possono avere le macchine di ogni marca
#macchine = { marca1=>{ tipoCarburante1=>{ modello1=>{ cilindrata => [consumo, nModelliCilindrataUguale], ... },... } gasolio=>{ ... }, ... }, ... }
def getModelli( macchine )
  #Invoca getTipiCarburante
  macchine = getTipiCarburante( macchine )
  #Itera nell'hash le marche come "marca" e i tipi di carburante come tipiCarburante
  macchine.each do |marca, tipiCarburante|
    #Itera in tipiCarburante i tipi di carburante come "tipoCarburante" e {} come modelli
    tipiCarburante.each do |tipoCarburante, modelli|
      #Scarica l'HTML
      source = Net::HTTP.get( 'www.ilsole24ore.com', '/speciali/emissioni_auto/emissioni_auto_emissioni_tipologia_' + marca + '_' + tipoCarburante + '.shtml' )
      #taglia la parte iniziale perchè non serve
      source = source[ source.index( "text-align:left;\" >" ) + 19 .. - 1 ]
      #trova i modelli con rispettive cilindrate e consumi e li aggiunge, il campo nModelliCilindrataUguale
      #nell'array serve perchè se ci sono più auto dello stesso modello generico con cilindrata uguale
      #viene fatta la media tra i consumi
      loop do
        #trova il modello
        modello = source[ 0 .. source.index( "</div>" ) - 1 ].strip.downcase
        #c'era un problema con la citroen che veniva scritta come citro&euml;n, quindi
        #abbiamo sostituito così
        modello = modello.sub( /&euml;/, "e" )
        #Alcune macchine hanno 2 spazi e non va bene
        modello = modello.sub( /  /, " " )
        modello = modello[ 0 .. - 3 ] if modello.end_with?(" *")
        #taglia il pezzo di stringa relativo al modello per mettere la cilindrata all'inizio
        source = source[ source.index( "text-align:right;\">" ) + 19 .. - 1 ]
        #prende la cilindrata e la approssima per eccesso a una cifra decimale: 1.723 diventa 1.8
        cilindrata = source[ 0 .. source.index( "</div>" ) - 1 ].strip.to_f.round(1)
        #toglie 3 righe inutili per avere il consumo medio all'inizio della stringa
        3.times do
          source = source[ source.index( "</div>" ) + 1 .. - 1 ]
        end
        #tagia il pezzo di stringa appena usato perchè non serve più
        source = source[ source.index( "text-align:left;\">" ) + 18 .. - 1 ]
        #ricava il consumo
        consumo = source[ 0 .. source.index( "<" ) - 1 ].strip.sub( /-/, '/')
        #se il modello attuale non è nell'hash, lo inserisce, altrimenti, se il modello attuale
        #con la cilindrata attuale non è nell'hash, la inserisce, altrimenti aggiunge il consumo
        #a quello degli altri e aggiunge 1 al numero di elementi con la stessa cilindrata perchè
        #poi verrà fatta la media, in caso il tipo di carburante è benzina-metano, benzina-etanolo
        #o benzina-gpl, ci sono i valori di entrambi i combustibili
        if tipoCarburante == 'metano-benzina' or tipoCarburante == 'gpl-benzina'
          #se è già presente una macchina con lo stesso modello
          if modelli[ modello ] != nil
            #se non è presente una macchina dello stesso modello con la stessa cilindrata viene creata
            if !modelli[ modello ].key?( cilindrata )
              consumo_benzina = consumo[ 0 .. consumo.index( "/" ) - 1 ].strip.to_f
              consumo_altroCarburante = consumo[ consumo.index( "/" ) + 1 .. - 1 ].strip.to_f
              modelli[ modello ][ cilindrata ] = [ [ consumo_benzina , consumo_altroCarburante ], 1 ]
            else
              #altrimenti vengono sommati i consumi e viene incrementato il contatore
              consumo_benzinaOld = modelli[ modello ][ cilindrata ][ 0 ][ 0 ]
              consumo_benzinaNew = consumo[ 0 .. consumo.index( "/" ) - 2 ].to_f
              consumo_benzina = consumo_benzinaNew + consumo_benzinaOld
              consumo_altroCarburanteOld = modelli[ modello ][ cilindrata ][ 0 ][ 0 ]
              consumo_altroCarburanteNew = consumo[ consumo.index( "/" ) + 2 .. - 1 ].to_f
              consumo_altroCarburante = consumo_altroCarburanteOld + consumo_altroCarburanteNew
              modelli[ modello ][ cilindrata ] = [ [ consumo_benzina , consumo_altroCarburante ], modelli[ modello ][ cilindrata ][ 1 ] + 1 ]
            end
          else
            #se non è già presente una macchina dello stesso modello viene creata
            consumo_benzina = consumo[ 0 .. consumo.index( "/" ) - 1 ].strip.to_f
            consumo_altroCarburante = consumo[ consumo.index( "/" ) + 1 .. - 1 ].strip.to_f
            modelli[ modello ] = { cilindrata => [ [ consumo_benzina, consumo_altroCarburante ], 1 ] }
          end
        else
          #se la macchina attuale non consuma due tipi di carburante separatamente
          if modelli[ modello ] != nil
            #se è già presente una macchina dello stesso modello, se non è presente una
            #macchina con la stessa cilindrata viene creata, altrimenti vengono sommati
            #i consumi e viene incrementato il contatore
            modelli[ modello ][ cilindrata ] = !modelli[ modello ].key?( cilindrata ) ? [ consumo.to_f, 1 ] : [ modelli[ modello ][ cilindrata ][ 0 ] + consumo.to_f, modelli[ modello ][ cilindrata ][ 1 ] + 1 ]
          else
            #altrimenti se non è già presente una macchina dello stesso modello, la crea
            modelli[ modello ] = { cilindrata => [ consumo.to_f, 1 ] }
          end
        end
        #esce se è l'ultimo
        break if source.index( "text-align:left;\" >" ) == nil
        #taglia la parte già usata dalla stringa
        source = source[ source.index( "text-align:left;\" >" ) + 19 .. - 1 ]
      end
      #fa la media dei consumi
      if tipoCarburante == 'metano-benzina' or tipoCarburante == 'gpl-benzina'
        modelli.each do |modello, datiModello|
          datiModello.each do |cilindrata, dati|
            dati[ 0 ][ 0 ] = ( 100 / ( dati[ 0 ][ 0 ] / dati[ 1 ] ) ).round(1)
            dati[ 0 ][ 1 ] = ( 100 / ( dati[ 0 ][ 0 ] / dati[ 1 ] ) ).round(1)
          end
        end
      else
        modelli.each do |modello, datiModello|
          datiModello.each do |cilindrata, dati|
            dati[ 0 ] = ( 100 / ( dati[ 0 ] / dati[ 1 ] ) ).round(1)
          end
        end
      end
    end
  end
end


def printConsumo()
  File.open('consumi.yaml', 'w') { |fo| fo.puts getModelli( Hash.new ).to_yaml }
end
def getConsumo()
  return getModelli(Hash.new)
end

if __FILE__ == $0
  t1 = Time.now
  printConsumo
  t2 = Time.now
  puts delta = t2 - t1
end
