# Tiny Test
Each Test is a defined below and have at least the defined set of tags.

    Tinytest.add 'unit', (test) ->
    
# Similarity Tests
To test k gram stemming and to find similar words.

      text = "kaufen kaufst kauf city cities junge jugendlich jugend"
      result = Yaki(text, language: 'de').extract()
      #showSimilarities result
      console.log result
      #test.equal result.similarities, [[0,1,2],[3,4],[6,7]]
    
# Full Tests

      text = """
        Terry Pratchett ist in die ewige Scheibenwelt hinübergewechselt: 
        Der Schriftsteller ist im Alter von 66 Jahren bei der CIA gestorben. Auch mit 
        Computerspielen hatte der Kultautor engen Kontakt.
      """
      #result = Yaki(text, {language: 'de'}).split().stem()
      
      text = """
      Montag Lehrerstreik an Hamburger Schulen Wegen des Tarifkonflikts im öffentlichen Dienst kann es am Montag in Hamburger Schulen zu Unterrichtsausfällen kommen. Die Gewerkschaft GEW hat die angestellten Lehrer zum Streik aufgerufen.
      """
      #result = Yaki(text, {language: 'de'}).analyse()
      #showSimilarities result
      #console.log result
      test.equal true, true  
      
      text = """
        FC Bayern München und FC Bayern München.
      """
      #result = Yaki(text, {language: 'de'}).extract()
      #console.log result.terms
      #console.log result
      
      text = """
        3. Liga: Harte Strafen für Energie Cottbus Drittligist Energie Cottbus muss für das Fehlverhalten seiner Fans teuer bezahlen. Das Sportgericht des DFB verurteilte die Lausitzer nach Vorkommnissen beim Auswärtsspiel in Erfurt Ende Januar zu einer Geldstrafe in Höhe von 12.000 Euro und einem Teilausschluss auf Bewährung.
      """
      #result = Yaki(text, {language: 'de'}).extract()
      #console.log result.terms
      #console.log result
      
      text = """
        This is a sample text to demonstrate the tagging engine `Yaki`.
      """
      #result = Yaki(text).extract()
      #console.log result.terms
      #console.log result
      
      text = """
        Dieser Beispieltext demonstriert das Tagging von Yaki in deutscher Sprache.
      """
      #result = Yaki(text, {language: 'de', tags: ['Yaki']}).extract()
      #console.log result.terms
      #console.log result
      
      #console.log Yaki(['legend', 'advanced.', 'MultiColor', '-> HTTP <-']).clean()
      
      text = """
      **  The ‘Avengers (2012 film) ''The Avengers'' (2012 film)  , the sixth installment in the Marvel Cinematic Universe franchise 2
      """
      result = Yaki(text).extract()
      #console.log result.terms
      #console.log result.similarities
      #console.log result
      
      text = """
      EuGH verhandelt über Übermittlung von Nutzerdaten in die USA
      Der Europäische Gerichtshof befasst sich von Dienstag an mit dem Schutz von Facebook-Daten in den USA. Hintergrund ist eine Klage des Österreichers Max Schrems.
      Der Europäische Gerichtshof (EuGH) befasst sich ab heute mit der Frage, inwieweit sich US-Unternehmen wie Facebook an EU-Datenschutzrechte halten müssen. Anlass ist eine Klage des Österreichers Max Schrems in Irland. Dort hat das soziale Netzwerk Facebook seinen Europasitz, es speichert Daten seiner Nutzer ganz oder zum Teil in den USA.

      Schrems hatte sich 2013 beim irischen Datenschutzbeauftragten darüber beschwert, dass persönliche Daten in den USA nicht vor staatlicher Überwachung geschützt seien und berief sich dabei auf die Enthüllungen des Informanten Edward Snowden.

      Der irische Datenschutzbeauftragte lehnte die Beschwerde ab. Dabei berief er sich unter anderem auf eine Entscheidung der EU-Kommission aus dem Jahr 2000, in der die Brüsseler Behörde das Schutzniveau der USA als ausreichend eingestuft hatte.

      Das zuständige irische Gericht will vom EuGH wissen, ob sich der Datenschutzbeauftragte auf die Brüsseler Entscheidung berufen durfte - oder ob er nicht vielmehr selbst hätte ermitteln können oder müssen. Das Urteil wird erst in einigen Monaten gefällt.
      """
      result = Yaki(text, {language: 'de'}).extract()
      #console.log result.tags
      #console.log result.similarities
      #showSimilarities result
      console.log result
      
      # Bind Words with Sopwords
      text = """
      World of Warcraft und die Marken
      Mit Ingame-Gold statt mit Euro können Spieler künftig ihr Abo von World of Warcraft über eine "WoW-Marke" bezahlen. Blizzard hat weitere Details zu dem System vorgestellt.
      Kurz vor der Veröffentlichung des Updates 6.1.2. von World of Warcraft in Deutschland am 25. März 2015 hat Blizzard weitere Informationen zu seinen WoW-Marken veröffentlicht. Die neue Währung soll in den kommenden Wochen zunächst in den USA, in Ozeanien und Lateinamerika und erst dann in weiteren Regionen eingeführt werden - auch in Europa.
      Eine WoW-Marke sollen Spieler für rund 20 US-Dollar (der Euro-Preis soll ähnlich hoch sein) kaufen und sie dann gegen 30 Tage Spielzeit eintauschen können. Alternativ kann die Marke aber auch im Auktionshaus gegen Ingame-Gold verkauft werden. Der Wert dort soll ausdrücklich nicht von Blizzard, sondern von Angebot und Nachfrage abhängen. "Wenn mehr WoW-Marken angeboten werden als sich Kaufinteressenten finden, wird der Preis mit der Zeit automatisch sinken", schreibt das Entwicklerstudio in seinem Blog.

      Dieser Marken-Markt soll nicht Realm-gebunden sein, sondern sich jeweils über die gesamte Region erstrecken - also ganz Amerika, Europa, Südkorea, Taiwan und China. Allerdings erfolgt die Bezahlung von Spielzeit in Asien nach einem anderen System als in Europa und Amerika, weil dort auch die Abos anders gehandhabt werden.

      Falls das System bei der Community ankommt, könnten Spieler zumindest theoretisch ihren Monat World of Warcraft vollständig mit Ingame-Gold bezahlen. Ob neben dem dafür möglicherweise nötigen "Gold farmen" noch Pausen für das eigentliche Rollenspiel bleiben, ist wieder eine andere Frage.

      Der Vorteil für Blizzard: eine vielleicht noch engagierter spielende Community. Außerdem könnte es einen tatsächlich funktionierenden Austausch von Spielern mit genug Echtgeld und solchen mit viel Zeit geben, ohne dass die Gesamtzahl an verkauften Abos deswegen sinkt.
      """
      result = Yaki(text, {language: 'de'}).extract()
      #console.log result.terms
      console.log result
      
# Outputs

## View Similarities

    showSimilarities = (dictionary) ->
      dictionary.similarities.map (sim, sid) ->
        console.log "Class: #{sid}:"
        console.log " - #{dictionary.terms[tid].term}" for tid in sim
      
