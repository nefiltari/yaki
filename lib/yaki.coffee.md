# Yaki - The standalone Tagging Engine
Yaki can capture all relevant tokens from a bunch of text. That means you can typecast your text with a set of tags. The `context` describe known facts in which the text is interpreted. Text analyse or text mining is a text transformation process to a chosen abstraction level for the right information need.
The `context` in an optional object that have follwoing keys:
- `language`: Language abbreviation (TLD-Specification) (Default: 'en')
- `natural`: Use only natural words instead of words like: foo_bar, foo-bar, 1__0 (Default: true)
- `moderated`: Is this a moderated text (true/false) (Default: true)
- `tags`: Possible an array of tags that **can** describe this article (more wheight on these tags when found)


    @Yaki = Yaki = (text, context) ->
      if @text
        @context = context if context
        return this
      else
        dictionary = new Array
        dictionary.context = context or {}
        lang = context.language or 'en'
        lang = if _.contains(Vocabulary.support, lang) then lang or 'en'
        dictionary.context.language = lang
        dictionary.split = Yaki.split
        dictionary.clean = Yaki.clean
        dictionary.stem = Yaki.stem
        dictionary.calculate = Yaki.calculate
        dictionary.combine = Yaki.combine
        dictionary.rank = Yaki.rank
        dictionary.extract = Yaki.extract
        if _.isArray text
          dictionary.text = text.join(' ')
          dictionary = dictionary.split()
        else
          dictionary.text = text
        return dictionary
      
## Define the Vocabular
The Vocabular describe the useable letters from diffrent languages.

    Yaki.Vocabulary = Vocabulary
    
## Define Stopwords
Stopword in multiple languages to filter high frequently words.

    Yaki.Stopwords = Stopwords
    
## Configuration
The algorithms need some metrics and variables to do the right things in an acceptable range.

    Yaki.Config = 
      # Stemming (Yaki.stem)
      k: 4
      similarity: 0.4
      # Calculation (Yaki.calculate)
      entropieStrength: 2
      frequencyCoefficient: 1.0
      positionCoefficient: 1.0
      capitalizeBonus: 5
      akkronymBonus: 20
      tagBonus: 30
      # Word Combination (Yaki.combine) & Analyse (Yaki.analyse)
      combinationOccurences: 2
      minQuality: 5
    
## Useful Helpers
This helpers are useful for internal functionality.

### `normalize`
Normalize a word (with special characters) to a term.

    normalize = (str, type) ->
      # Negates dot notations from akkronymes: U.S.A. -> USA
      # Each logical piece or fragment from a word is sgned by an '_' e.g. 9/11 -> 9_11, hallo- -> hallo_
      # All underscores from begin and end are trimed: e.g. _hallo_ -> hallo
      # Each normalized word (term) is converted into lower case e.g. USA -> usa, 
      str = str.replace(/\./g, '') if type is 'akkr'
      str = str.replace(/[\/\\\.\-\#\+\*\:\,\?\'\"\`\´\=\&\%\$\§\!\(\)\]\[\<\>\;\^\°]/g, '_')
      str = str.replace(/^\_*/, '')
      str = str.replace(/\_*$/, '')
      str.toLowerCase()
    
### `toKGram`    
Convert a term to a k-gram. For better index construction an optional callback can call each k-gram piece. Minimum for k is 2.
      
    toKGram = (term, k, callback) ->
      grams = []
      for i in [1..(k-1)]
        gram = term.substr 0, i
        gram = " #{gram}" while gram.length < k
        if callback then callback(gram) else grams.push(gram)
      for char, i in term
        gram = term.substr i, k
        gram = "#{gram} " while gram.length < k
        if callback then callback(gram) else grams.push(gram)
      return grams
      
### `entropy`
The entropy from a term. The source parameter define the relativ frequency from a vocabulary.

    entropy = (term, source) ->
      # Entropy: - Sum over each Character: (pi * log2 pi)
      sum = (akk, char) ->
        if source[char]?
          akk + (source[char] * (Math.log(source[char]) / Math.log(2)))
        else akk
      -1 * term.split('').reduce sum, 0
      
## Splitting
The splitting process cuts a text into single terms.

    Yaki.split = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      dictionary.length = 0
      # Split text into words
      text = dictionary.text.replace /[\s\-]+/g, ' '
      dictionary.terms = text.split(' ').map (term, id) ->
        dictionary.push term
        entry =  
          id: id
          position: id
          term: term
      return dictionary
      
## Cleaning
Clean the result. Define a term type and normalize each word. Filter the list with Stopwords.

    Yaki.clean = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.terms
      lang = dictionary.context.language
      # Define language dependent reqex's
      vocabular = Vocabulary[lang]
      regex = [
        new RegExp "^[#{vocabular.uppercase}#{vocabular.lowercase}]\\."
        new RegExp "^[#{vocabular.uppercase}]{2,}"
        new RegExp "^[#{vocabular.uppercase}]"
      ]
      # Determine type and normalize each term
      for entry, id in dictionary.terms
        entry.type = switch
          when regex[0].test(entry.term) then 'akkr'  # matches U.S.A, u.s.a.
          when regex[1].test(entry.term) then 'akkr'  # matches USA, HTTP but not A (single letter)
          when regex[2].test(entry.term) then 'capi'  # matches capitalized words
          else 'norm'
        entry.term = normalize(entry.term, entry.type)
      # Count Words (before the any filter steps in)
      dictionary.words = dictionary.terms.length
      # Filter blank terms
      dictionary.terms = _.reject dictionary.terms, (entry) ->
        entry.term is ''
      # If natural filter are defined (isnt false for '===')
      if dictionary.context.natural isnt false
        dictionary.terms = _.reject dictionary.terms, (entry) ->
          new RegExp(/\_/).test entry.term
      # Filter with Stopwords
      dictionary.terms = _.reject dictionary.terms, (entry) ->
        _.contains Yaki.Stopwords[lang], entry.term
      # Recalculate Id's and link to result
      dictionary.length = 0
      for entry, id in dictionary.terms
        entry.id = id
        dictionary.push entry.term
      return dictionary    

## Stemmming
Convert each term into a token. Each token has multiple occurences in text. That means multiple terms have one token. Tokens are represented as K-Grams. Construct a K-gram index for better access to find similar terms. The distance between two terms follows the dice coefficient. It is Language independant.

    Yaki.stem = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.terms
      dictionary.index = {}
      dictionary.similarities = []
      for entry, id in dictionary.terms
        # Initialize some Variables
        candidates = {}
        count = 0
        max = 0
        # Process the K-Gram and gather data about possible similarities
        toKGram entry.term, Yaki.Config.k, (gram) ->
          # Insert gram into index with term id and
          # Fill the similarity vector with possible similarities
          # The variables max sign the similariest founded term
          if dictionary.index[gram]? and _.last(dictionary.index[gram]) isnt id
            for i in dictionary.index[gram]
              candidates[i] = if candidates[i]? then candidates[i] + 1 else 1
              max = candidates[i] if candidates[i] > max 
            dictionary.index[gram].push id
          else
            dictionary.index[gram] = [id]
          count += 1
        # Calculate Dice Distance for the possible similar terms and choose the best
        if max isnt 0
          similarity = 0
          best = 0
          # Find the best similarity over multiple candidates
          for candidate, intersect of candidates when intersect is max
            # Dice:    ( 2 * |Intersect(a,b)| ) / ( |a| + |b| )
            distance = (2 * intersect) / (dictionary.terms[candidate*1].kGramCount + count)
            if distance > Yaki.Config.similarity and distance > similarity
              similarity = distance
              best = candidate*1
          # Similar Term found (best): Register in dictionary.similarities (counter array)
          if similarity isnt 0
            if dictionary.terms[best].similar?
              number = dictionary.terms[best].similar
              dictionary.terms[id].similar = number
              dictionary.similarities[number].push id
            else
              number = dictionary.similarities.length
              dictionary.terms[best].similar = number
              dictionary.terms[id].similar = number
              dictionary.similarities[number] = [best, id]
        # Create an attribute for the K-Gram length of terms
        dictionary.terms[id].kGramCount = count
      return dictionary
    
## Calculate Quality
Calculates each token entropy with language vocabular and token frequency. Add bonus points to special term types. In moderated mode the Word position inside the text is also relevant.

    Yaki.calculate = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.terms
      lang = dictionary.context.language
      for entry, id in dictionary.terms when not entry.quality?
        # Step 1: Basic Entropy (included word length and relative term frequency)
        quality = entropy entry.term, Yaki.Vocabulary[lang].frequencies
        #  Strengthen the entropie
        quality = Math.pow quality, Yaki.Config.entropieStrength
        # Step 2: Term Frequency: Lun'sches law (Config: Coefficient)
        frequency = if entry.similar? then dictionary.similarities[entry.similar].length else 1
        quality = quality * (Yaki.Config.frequencyCoefficient * frequency)
        # Step 3: Capitalized word bonus and Akkronym Bonsu (Config: Bonus)
        quality = quality + Yaki.Config.capitalizeBonus if entry.type is 'capi'
        quality = quality + Yaki.Config.akkronymBonus if entry.type is 'akkr'
        # Step 4: Term Position (Config: Coefficient) (isnt false for '===')
        #if dictionary.context.moderated isnt false
          # Standard normal distribution (Normalized for x and y)
          # Construct the normalized value from id (currently disabled)
          #x = -4 + (id / dictionary.terms.length) * 8
          #weight = 1 - ((1 / Math.sqrt(2 * Math.PI)) * Math.exp(-0.5*x*x))
          #quality = quality * Yaki.Config.positionCoefficient * weight
        # Step 5: Known Context Tags (Config: Bonus)
        if dictionary.context.tags?
          if _.contains dictionary.context.tags, entry.term
            quality = quality + Yaki.Config.tagBonus
        dictionary.terms[id].quality = Math.round quality
      return dictionary
        
## Word Combinations
Find any word combinations and semantical rules between words/terms.

    Yaki.combine = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.similarities
      for similarity, sid in dictionary.similarities
        combo = {}
        best = -1
        quality = 0
        for tid in similarity when dictionary.terms[tid].quality >= Yaki.Config.minQuality
          current = dictionary.terms[tid]
          next = dictionary.terms[tid+1]
          if next? and next.similar? and next.quality >= Yaki.Config.minQuality
            if (current.position+1) is next.position 
              # Gather different similar classes that direct follow a term          
              combo[next.similar] = (combo[next.similar] or 0) + 1
              if combo[next.similar] >= Yaki.Config.combinationOccurences # high pass
                if (combo[next.similar] * next.quality) > quality
                  best = next.similar
                  quality = combo[next.similar] * next.quality
        if best > -1
          for tid in similarity
            if _.contains dictionary.similarities[best], (tid+1)
              dictionary.terms[tid].follow = tid+1
              dictionary.terms[tid].quality += dictionary.terms[tid+1].quality
      return dictionary
    
## Ranking
Rank the Terms for better access. The top most terms (highest quality) can used to identify the text.

    Yaki.rank = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.terms
      dictionary.ranking = _.sortBy dictionary.terms, 'quality'
      dictionary.ranking.reverse()
      dictionary.length = 0
      dictionary.push entry.term for entry in dictionary.ranking
      return dictionary    
      
## Extract
This function is an full standard process for text mining and analysing and combines different functions in a logical order to retrieve ranked normalized and combined tags.

    Yaki.extract = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      dictionary = dictionary.split().clean().stem().calculate().combine().rank()
      result = dictionary.ranking
      # Step 1: Filter the ranking (high pass) by a minimum quality
      result = _.filter result, (entry) ->
        entry.quality > Yaki.Config.minQuality
      # Step 2: Filter terms that has the same similarity class (behold the best similar term)
      similarities = []
      result = _.filter result, (entry) ->
        if entry.similar? and _.contains similarities, entry.similar
          return false
        else
          similarities.push entry.similar
          return true
      # Step 3: Look up for word combinations (Map + Filter) and sign used combinations
      used = []
      result = for entry in result when not _.contains used, entry.id
        next = entry
        while next.follow?
          next = dictionary.terms[next.follow]
          entry.term = "#{entry.term} #{next.term}"
          used.push next.id
        entry
      # Update Dictionary
      dictionary.length = 0
      dictionary.push entry.term for entry in result
      # Return the dictionary
      return dictionary
