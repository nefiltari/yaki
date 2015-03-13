# Yaki - The standalone Tagging Engine
Yaki can capture all relevant tokens from a bunch of text. That means you can typecast your text with a set of tags. The `context` describe known facts in which the text is interpreted. Text analyse or text mining is a text transformation process to a chosen abstraction level for the right information need.
The `context` in an optional object that have follwoing keys:
- `language`: Language abbreviation (TLD)
- `moderated`: Is this a moderated text (true/false)
- `type`: A text type like `'headline'` or `'summary'`
- `tags`: Possible an array of tags that **can** describe this article (more wheight on these tags when found)

    @Yaki = Yaki = (text, context) ->
      if @text
        @context = context if context
        return this
      else
        dictionary = {text: text}
        dictionary.context = context or {}
        dictionary.split = Yaki.split
        dictionary.stem = Yaki.stem
        dictionary.calculate = Yaki.calculate
        dictionary.combine = Yaki.combine
        dictionary.rank = Yaki.rank
        dictionary.analyse = Yaki.analyse
        return dictionary
      
## Define the Vocabular
The Vocabular describe the useable letters from diffrent languages.

    Yaki.Vocabulary = Vocabulary
    
## Define Stopwords
Stopword in multiple languages to filter high frequently words.

    Yaki.Stopwords = Stopwords
    
## Configuration
The algorithms need some metrics to do the right things in an acceptable range.

    Yaki.Config = 
      # Stemming (Yaki.stem)
      k: 4
      similarity: 0.4
      # Calculation (Yaki.calculate)
      entropieStrength: 2
      frequencyCoefficient: 1.0
      positionCoefficient: 1.0
      capitalizeBonus: 10
      akkronymBonus: 20
      tagBonus: 10
      # Word Combination (Yaki.combine)
      combinationOccurences: 2
      sourceMinQuality: 5
      targetMinQuality: 5
      # Ranking & Filter
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
        else akk + 1
      -1 * term.split('').reduce sum, 0
      
## Splitting
The splitting process cuts a text in single terms. Each term is normalized.

    Yaki.split = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      # Define language dependent reqex's
      lang = dictionary.context.language or 'en'
      vocabular = Yaki.Vocabulary[lang]
      regex = [
        new RegExp "^[#{vocabular.uppercase}#{vocabular.lowercase}]\\."
        new RegExp "^[#{vocabular.uppercase}]{2,}"
        new RegExp "^[#{vocabular.uppercase}]"
      ]
      # Split text into words
      text = dictionary.text.replace /[\s\-]+/g, ' '
      dictionary.terms = text.split ' '
      dictionary.count = dictionary.terms.length
      # Convert words to terms
      dictionary.terms = dictionary.terms.map (word) ->
        entry = {}
        entry.word = word
        entry.type = switch
          when regex[0].test(word) then 'akkr'  # matches U.S.A, u.s.a.
          when regex[1].test(word) then 'akkr'  # matches USA, HTTP but not A (single letter)
          when regex[2].test(word) then 'capi'  # matches capitalized words
          else 'norm'
        entry.term = normalize entry.word, entry.type
        return entry
      # Optional Pre-Filter to reduce the number of terms goes here eg. StopWords
      dictionary.terms = _.filter dictionary.terms, (entry) ->
        not _.contains Yaki.Stopwords[lang], entry.term
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
    
## Calculations Quality
Calculates each token entropy with language vocabular and token frequency. In moderated mode: The Word position inside the text is also relevant.

    Yaki.calculate = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.terms
      lang = dictionary.context.language or 'en'
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
        # Step 4: Term Position (Config: Coefficient)
        if dictionary.context.moderated
          # Standard normal distribution (Normalized for x and y)
          # Construct the normalized value from id
          x = -4 + (id / dictionary.count) * 8
          weight = 1 - ((1 / Math.sqrt(2 * Math.PI)) * Math.exp(-0.5*x*x))
          quality = quality * Yaki.Config.positionCoefficient * weight
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
      dictionary.combinators = []
      for similarity, sid in dictionary.similarities
        combo = {}
        best = -1
        quality = 0
        for tid in similarity when dictionary.terms[tid].quality > Yaki.Config.sourceMinQuality
          next = dictionary.terms[tid+1]
          if next? and next.similar? and next.quality > Yaki.Config.targetMinQuality
            # Gather diffrent similar classes that direct follow a word
            combo[next.similar] = (combo[next.similar] or 0) + 1
            if combo[next.similar] > Yaki.Config.combinationOccurences # high pass
              if (combo[next.similar] * next.quality) > quality
                best = next.similar
                quality = combo[next.similar] * next.quality
        if best > -1
          for tid in similarity
            if _.contains dictionary.similarities[best], (tid+1)
              dictionary.combinators.push tid
      return dictionary
    
## Ranking
Rank the Terms for better access. The top most terms (highest quality) can used to identify the text.

    Yaki.rank = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.terms
      dictionary.ranking = _.sortBy dictionary.terms, 'quality'
      dictionary.ranking = _.filter dictionary.ranking, (term) ->
        term.quality > Yaki.Config.minQuality
      dictionary.ranking.reverse()
      return dictionary
      
# Analysing
This function is an full standard process for text mining and analysing and combines different functions in a logical order to retrieve ranked tags.

    Yaki.analyse = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      dictionary.split().stem().calculate().combine().rank()
      # Convert to a simple tags array
      _.uniq dictionary.ranking.map (entry) -> entry.term
      
      
