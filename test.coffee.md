# Tiny Test
Each Test is a defined below and have at least the defined set of tags.

    Tinytest.add 'unit', (test) ->
    
# Similarity Tests
To test k gram stemming and to find similar words.

      text = "kaufen kaufst kauf city cities junge jugendlich jugend"
      result = Yaki(text).split().stem()
      #showSimilarities result
      #test.equal result.similarities, [[0,1,2],[3,4],[6,7]]
    
# Full Tests

      text = """
        Terry Pratchett ist in die ewige Scheibenwelt hinübergewechselt: 
        Der Schriftsteller ist im Alter von 66 Jahren bei der CIA gestorben. Auch mit 
        Computerspielen hatte der Kultautor engen Kontakt.
      """
      result = Yaki(text, {language: 'de'}).split().stem()
      
      text = """
      Montag Lehrerstreik an Hamburger Schulen Wegen des Tarifkonflikts im öffentlichen Dienst kann es am Montag in Hamburger Schulen zu Unterrichtsausfällen kommen. Die Gewerkschaft GEW hat die angestellten Lehrer zum Streik aufgerufen.
      """
      result = Yaki(text, {language: 'de'}).analyse()
      #showSimilarities result
      #console.log result
      test.equal true, true  
      
      text = """
        FC Bayern München und FC Bayern München.
      """
      result = Yaki(text, {language: 'de'}).split().stem().calculate().combine().rank()
      console.log result.similarities
      console.log result.combinators
      
      text = """
        3. Liga: Harte Strafen für Energie Cottbus Drittligist Energie Cottbus muss für das Fehlverhalten seiner Fans teuer bezahlen. Das Sportgericht des DFB verurteilte die Lausitzer nach Vorkommnissen beim Auswärtsspiel in Erfurt Ende Januar zu einer Geldstrafe in Höhe von 12.000 Euro und einem Teilausschluss auf Bewährung.
      """
      result = Yaki(text, {language: 'de'}).split().stem().calculate().combine().rank()
      console.log result.similarities
      
# Outputs

## View Similarities

    showSimilarities = (dictionary) ->
      dictionary.similarities.map (sim, sid) ->
        console.log "Class: #{sid}:"
        console.log " - #{dictionary.terms[tid].term}" for tid in sim
      
