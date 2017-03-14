require_relative 'getConsumo'
require_relative 'getDistance'
require_relative 'findCar'

macchina = ARGV[ 0 .. ARGV.index("/") - 1 ].join(" ")
secondoElemento = nil
partenza = ""
ARGV.each do |elemento|
  break if secondoElemento == true and elemento == "/"
  partenza += " " + elemento if secondoElemento == true
  secondoElemento = true if elemento == "/"
end

partenza = partenza[ 1 .. - 1 ]
destinazione = ARGV[ ARGV.rindex( "/" ) + 1 .. -1 ].join(" ")
def getConsumoPerDistanza(macchina, partenza, destinazione)
	consumi = getConsumo
	kmPerUnita, tipoCarburante = cercaConsumo(macchina, consumi)
	distanza = getDistanza(partenza,destinazione)
	unless macchina.split[ - 1 ].downcase == "metano-benzina" or macchina.split[ - 1 ] == "gpl-benzina"
	  consumo = (distanza["value"]/1000) / kmPerUnita
	  p "Per andare da '#{partenza}' a '#{destinazione}' con una '#{macchina}' si consumano #{consumo} litri di #{tipoCarburante}"
	else
	  consumo_benzina = (distanza["value"]/1000) / kmPerUnita[0]
	  consumo_altroCarburante = (distanza["value"]/1000) / kmPerUnita[1]
	  p "Per andare da '#{partenza}' a '#{destinazione}' con una '#{macchina}' si consumano #{consumo_benzina} litri di #{tipoCarburante.split("-")[1]}"
	  if tipoCarburante.split("-")[0] == "metano"
	    p "Per andare da '#{partenza}' a '#{destinazione}' con una '#{macchina}' si consumano #{consumo_altroCarburante} metri cubi di metano"
	  else
	    p "Per andare da '#{partenza}' a '#{destinazione}' con una '#{macchina}' si consumano #{consumo_benzina} litri di #{tipoCarburante.split("-")[0]}"
	  end
	end
end
