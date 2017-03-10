require_relative 'getConsumo'
require_relative 'getDistance'

partenza = 'via san pietro 3 38057'
destinazione = 'via venzia 17/c 38050 tenna'
distanza = getDistanza(partenza,destinazione)


consumi = getConsumo

consumo = (distanza["value"]/1000) / consumi["rolls-royce"]["benzina"]["rolls-royce phantom drophead"][6.8][0]

p 'per andare da '+partenza+' a '+destinazione+' si consumano '+consumo.to_s+' litri di benzina'
