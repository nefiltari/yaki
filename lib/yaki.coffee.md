# Yaki - The standalone Tagging Engine
Yaki can capture all relevant tokens from a bunch of text. That means you can typecast your text with a set of tags. The `context` describe known facts in which the text is interpreted. Text analyse or text mining is a text transformation process to a chosen abstraction level for the right information need.

    @Yaki = Yaki = (text, context) ->
      if text?.text
        text.context = context if context
        return text
      else
        dictionary = {text: text}
        dictionary.context = if context then context else {language: 'en'}
        dictionary.split = Yaki.split
        dictionary.stem = Yaki.stem
        dictionary.entropy = Yaki.entropy
        dictionary.rank = Yaki.rank
        dictionary.analyse = Yaki.analyse
        return dictionary
      
## Define the Vocabular
The Vocabular describe the useable letters from diffrent languages.

    Yaki.vocabulary = Vocabulary
      
## Splitting

    Yaki.split = (dictionary, context) ->
      dictionary = if @text then this else Yaki dictionary, context
      # ...
      return dictionary
    
## Stemmming

    Yaki.stem = (dictionary, context) ->
      dictionary = if @text then this else Yaki dictionary, context
      # ...
      return dictionary
    
## Entropie

    Yaki.entropy = (dictionary, context) ->
      dictionary = if @text then this else Yaki dictionary, context
      # ...
      return dictionary
    
## Ranking

    Yaki.rank = (dictionary, context) ->
      dictionary = if @text then this else Yaki dictionary, context
      # ...
      return dictionary
      
# Analysing

    Yaki.analyse = (dictionary, context) ->
      dictionary = if @text then this else Yaki dictionary, context
      dictionary.split().stem().entropy().rank()
      return dictionary
      
      
