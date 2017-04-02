#API KEY = AIzaSyCvVPw6LzY6DBy0V5eWB6w1LI5k_CiML7A
require "net/http"
require "uri"
require 'json'

def getDistanza(source, destination)
  #fai la richiesta
  uri = URI.parse("https://maps.googleapis.com/maps/api/distancematrix/json?origins="+source+"&destinations="+destination+"&language=it-IT&key=AIzaSyCvVPw6LzY6DBy0V5eWB6w1LI5k_CiML7A")

  #Ricevi la risposta e ricava i dati utili
  response = Net::HTTP.get_response(uri)
  return distance = JSON.parse(response.body)["rows"][0]["elements"][0]["distance"]

  #distance["text"] è una stringa con x,y km
  #distance["value"] è un int con la distanza in metri
end
