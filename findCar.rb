
#'Marca Modello Cilindrata TipoCarburante'

def cercaConsumo(nome, dati)
  marca = nil
  tipoCarburante = nil
  nome = nome.downcase
  loop do
    if dati.key?( nome[ 0 .. nome.index( " " ) - 1 ] )
      marca = nome[ 0 .. nome.index( " " ) - 1 ]
      nome = nome[ nome.index( " " ) + 1 .. - 1 ]
    else
      nome[ nome.index( " " ) ] = "_"
    end
    break if marca != nil
  end
  loop do
    if dati[marca].key?(nome[ nome.rindex( " " ) + 1 .. - 1 ] ) != nil
      tipoCarburante = nome[ nome.rindex( " " ) + 1 .. - 1 ]
      nome = nome[ 0 .. nome.rindex( " " ) -1 ]
    else
      nome[ nome.rindex( " " ) ] = "_"
    end
    break if tipoCarburante != nil
  end
  cilindrata = nome[ - 3 .. - 1 ].to_f
  nome = nome[ 0 .. - 4 ].strip
  modello = nome
  return dati[ marca ][ tipoCarburante ][ marca.sub( /_/, " " ) + " " + modello ][ cilindrata ], tipoCarburante
end
