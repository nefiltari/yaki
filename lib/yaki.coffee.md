# Yaki - The standalone Tagging Engine
Yaki can capture all relevant tokens from a bunch of text. That means you can typecast your text with a set of tags. The `context` describe known facts in which the text is interpreted. Text analyse or text mining is a text transformation process to a chosen abstraction level for the right information need.
The `context` in an optional object that have follwoing keys:
- `language`: Language abbreviation (TLD-Specification) (Default: 'en')
- `moderated`: Is this a moderated text (true/false) (Default: true)
- `filter`: Enables or disables the high pass filter for found tags (Default: true)
- `tags`: Possible an array of tags that **can** describe this article (more wheight on these tags when found)


    @Yaki = Yaki = (text, context) ->
      if @text
        @context = context if context
        return this
      else
        # Initialize
        dictionary = new Array
        # Context
        context = context or {}
        unless _.contains(Yaki.Vocabulary.support, context.language)
          context.language = 'en'
        context.tags = Yaki(context.tags).clean() if context.tags
        dictionary.context = context
        # Methods
        dictionary.split = Yaki.split
        dictionary.normalize = Yaki.normalize
        dictionary.cleans = Yaki.cleans
        dictionary.stem = Yaki.stem
        dictionary.calculate = Yaki.calculate
        dictionary.combine = Yaki.combine
        dictionary.rank = Yaki.rank
        dictionary.extract = Yaki.extract
        dictionary.clean = Yaki.clean
        dictionary.inspect = Yaki.inspect
        # Text
        if _.isArray text
          text = text.map (tag) -> tag.replace /\s+/g, '_'
          dictionary.text = text.join(' ')
          dictionary = dictionary.split()
        else
          dictionary.text = text
        dictionary
      
## Define the Vocabular
The Vocabular describe the useable letters from diffrent languages.

    Yaki.Vocabulary = Vocabulary
    
## Define Stopwords
Stopword in multiple languages to filter high frequently words.

    Yaki.Stopwords = Stopwords
    
## Configuration
The algorithms need some metrics and variables to do the right things in an acceptable range.

    Yaki.Configuration = Configuration
    
## Inspector
The inspect routine for node's console.log.

    Yaki.inspect = (dictionary) -> 
      Npm.require('util').inspect _.toArray this or dictionary
    
## Useful Helpers
This helpers are useful for internal functionality.

### `normalize`
Normalize a word (with special characters) to a term.

    normalize = (term, type, letters) ->
      # Negates dot notations from akkronymes: U.S.A. -> USA
      # Each logical piece or fragment from a word is sgned by an '_' e.g. 9/11 -> 9_11, hallo- -> hallo_
      # All underscores from begin and end are trimed: e.g. _hallo_ -> hallo
      # Each normalized word (term) is converted into lower case e.g. USA -> usa,
      # Converts multiple underscores (inbound) to an whitespace (acts like a 'natural' word combination)
      str = term
      str = str.replace(/\./g, '') if type is 'akro'
      str = str.replace(/\'/g, '')
      regex = new RegExp("[^#{letters}]",'g')
      str = str.replace(regex, '_')
      str = str.replace(/^\_*/, '')
      str = str.replace(/\_*$/, '')
      str = str.replace(/\_+/g, ' ')
      # Workaround for wikipedias opensearch engine (Future: Representation Concepts)
      if type is 'akro' then str else str.toLowerCase()
    
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
      text = dictionary.text.replace /\s+/g, ' '
      dictionary.terms = text.split(' ').map (term, id) ->
        dictionary.push term
        entry =  
          id: id
          term: term
      return dictionary
      
## Normalize
Normalize each term to a more useable form.

    Yaki.normalize = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      dictionary.split() unless dictionary.terms
      # Define reqex's for typing each term
      upper = Yaki.Vocabulary.uppercase
      lower = Yaki.Vocabulary.lowercase
      letters = Yaki.Vocabulary.letters
      regex = [
        new RegExp "^[^#{upper}#{lower}]*[#{lower}#{upper}]\\."
        new RegExp "^[^#{upper}#{lower}]*[#{upper}]{2,5}"
        new RegExp "^[^#{upper}#{lower}]*[#{upper}]"
      ]
      # Determine type and normalize each term
      terms = []
      for entry, i in dictionary.terms
        entry.type = switch
          when regex[0].test(entry.term) then 'akro'  # matches U.S.A, u.s.a.
          when regex[1].test(entry.term) then 'akro'  # matches USA, HTTP but not A (single letter)
          when regex[2].test(entry.term) then 'capi'  # matches capitalized words
          else 'norm'
        entry.term = normalize entry.term, entry.type, letters
        # Additonal Splitting from chained terms (type: part)
        for term, i in entry.term.split ' '
          if i is 0
            entry.term = term
            entry.id = terms.length
            terms.push entry
          else
            entry = {term: term, id: terms.length, type: 'part'}
            terms.push entry
          dictionary[entry.id] = entry.term
      # Count Words (before the any filter/cleaning steps in)
      dictionary.words = dictionary.terms.length
      dictionary.terms = terms
      dictionary
      
## Cleansing
Cleans the result. Define a term type and normalize each word. Filter the list with Stopwords.

    Yaki.cleans = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      dictionary.normalize() unless dictionary.terms
      lang = dictionary.context.language
      dictionary.length = 0
      for entry, i in dictionary.terms
        entry.drop = false
        # Filter blank terms
        entry.drop or= entry.term is ''
        # Filter with Stopwords
        if Yaki.Stopwords[lang]
          stopword = _.contains Yaki.Stopwords[lang], entry.term
          entry.drop or= entry.type isnt 'akro' and stopword
        # Add to result
        dictionary.push entry.term unless entry.drop
      return dictionary    

## Stemmming
Convert each term into a token. Each token has multiple occurences in text. That means multiple terms have one token. Tokens are represented as K-Grams. Construct a K-gram index for better access to find similar terms. The distance between two terms follows the dice coefficient. It is Language independant.

    Yaki.stem = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      dictionary.cleans() unless dictionary.terms
      dictionary.index = {}
      dictionary.similarities = []
      lang = dictionary.context.language
      config = Yaki.Configuration[lang]
      for entry, id in dictionary.terms when not entry.drop
        # Initialize some Variables
        candidates = {}
        count = 0
        max = 0
        # Process the K-Gram and gather data about possible similarities
        toKGram entry.term, config.k, (gram) ->
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
            if distance > config.similarity and distance > similarity
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
Calculates each token entropy with language vocabular and token frequency. Add bonus points to special term types. In moderated mode the Word position inside the text is also relevant. Needs Calculation.

    Yaki.calculate = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      dictionary.stem() unless dictionary.terms 
      lang = dictionary.context.language
      config = Yaki.Configuration[lang]
      for entry, id in dictionary.terms when not entry.quality and not entry.drop
        # Step 1: Basic Entropy (included word length and relative term frequency)
        quality = entropy entry.term, Yaki.Vocabulary[lang].frequencies
        quality = Math.round quality
        #  Strengthen the entropie
        quality = Math.pow quality, config.entropieStrength
        # Step 2: Term Frequency: Lun'sches law (Config: Coefficient)
        frequency = if entry.similar? then dictionary.similarities[entry.similar].length else 1
        quality = quality * (config.frequencyCoefficient * frequency)
        # Step 3: Capitalized word bonus and Akkronym Bonsu (Config: Bonus)
        quality = quality + config.capitalizeBonus if entry.type is 'capi'
        quality = quality + config.akkronymBonus if entry.type is 'akro'
        # Step 4: Term Position (Config: Coefficient) (isnt false for '===')
        #if dictionary.context.moderated isnt false
          # Standard normal distribution (Normalized for x and y)
          # Construct the normalized value from id (currently disabled)
          #x = -4 + (id / dictionary.terms.length) * 8
          #weight = 1 - ((1 / Math.sqrt(2 * Math.PI)) * Math.exp(-0.5*x*x))
          #quality = quality * config.positionCoefficient * weight
        # Step 5: Known Context Tags (Config: Bonus)
        if dictionary.context.tags?
          if _.contains dictionary.context.tags, entry.term
            quality = quality + config.tagBonus
        dictionary.terms[id].quality = Math.round quality
      return dictionary
        
## Word Combinations
Find any word combinations and semantical rules between words/terms.

    Yaki.combine = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      dictionary.calculate() unless dictionary.similarities
      lang = dictionary.context.language
      config = Yaki.Configuration[lang]
      similar = dictionary.similarities.length - 1
      for similarity, sid in dictionary.similarities
        combo = {}
        best = -1
        quality = -1
        for tid in similarity
          current = dictionary.terms[tid]
          next = dictionary.terms[tid+1]
          if next? and next.similar >= 0
            # Gather different similar classes that direct follow a term          
            combo[next.similar] = (combo[next.similar] or 0) + 1
            if combo[next.similar] >= config.combinationOccurences
              if (combo[next.similar] * next.quality) > quality
                best = next.similar
                quality = combo[next.similar] * next.quality
        if best > -1
          similar += 1
          for tid in similarity
            if _.contains dictionary.similarities[best], (tid+1)
              dictionary.terms[tid].follow = true
              dictionary.terms[tid].similar = similar
      # Construct word combinations in dictionary.terms
      last = null
      for entry, i in dictionary.terms.reverse()
        if entry.follow
          last.drop = true
          entry.quality += last.quality
          entry.similar += last.similar
          entry.term = "#{entry.term} #{last.term}"
        last = entry
      dictionary.terms.reverse()
      return dictionary
    
## Ranking
Rank the Terms for better access. The top most terms (highest quality) can used to identify the text.

    Yaki.rank = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      dictionary.combine() unless dictionary.terms
      dictionary.ranking = _.reject dictionary.terms, (entry) -> entry.drop
      dictionary.ranking = _.sortBy dictionary.ranking, 'quality'
      dictionary.ranking.reverse()
      dictionary.length = 0
      dictionary.push entry.term for entry in dictionary.ranking
      return dictionary    
      
## Clean
Combine (splitting), normalization and cleansing.

    Yaki.clean = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      dictionary = dictionary.split() unless dictionary.terms
      return dictionary.normalize().cleans()
      
## Extract
This function is an full standard process for text mining and analysing and combines different functions in a logical order to retrieve ranked normalized and combined tags.

    Yaki.extract = (dictionary, context) ->
      dictionary = Yaki.call this, dictionary, context
      return dictionary unless dictionary.text
      lang = dictionary.context.language
      config = Yaki.Configuration[lang]
      dictionary = dictionary.split().normalize().cleans().stem().calculate().combine().rank()
      result = dictionary.ranking
      # Step 1: Filter the ranking (high pass) by a minimum quality
      if dictionary.context.filter isnt false
        result = _.filter result, (entry) ->
          entry.quality >= config.minQuality
      # Step 2: Filter terms that has the same similarity class (behold the best similar term)
      similarities = []
      result = _.filter result, (entry) ->
        if entry.similar >= 0 and _.contains similarities, entry.similar
          return false
        else
          similarities.push entry.similar
          return true
      # Save Result
      dictionary.tags = result
      # Update Dictionary
      dictionary.length = 0
      dictionary.push entry.term for entry in result
      # Return the dictionary
      return dictionary
