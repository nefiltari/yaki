# Yaki
Yaki can capture relevant tags from any bunch of text. Works on the client and on the server. 

Features from Yaki:
- Uses term normalizations to construct a list of terms
- Uses Stopword Lists and a language dependent alphabet as dictionaries
- Calculates tag relevance via statisitcal methods: like entropy and standard normal distribution
- Uses [n-Gram](http://en.wikipedia.org/wiki/N-gram) for stemming and simmilarity detection
- Can find word combinations (in case of multiple occurences)
- Currently supported languages: english and german
- Uses language dependent feature configurations to improve QoS

Text Retrieval classification: *morphology* and parts of *syntax* (without vocabulary)

***Beware***: This is an early alpha test release and NOT suitable for production.

### Installation

```shell
  $ meteor add nefiltari:yaki
```

### How-To
For simple tagging (most features are activated by default) use following syntax: 
```coffee
  text = "This is a sample text to demonstrate the tagging engine `Yaki`."
  console.log Yaki(text).extract()
  # -> [ 'demonstrate', 'yaki', 'engine', 'tagging' ]
```

If you know the language then you can specify this as second parameter (use the Top Level Domain abbreviation).
The default language is english.
Use additional (maybe) known tags to add a stronger weight to some words.
```coffee
  text = "Dieser Beispieltext demonstriert das Tagging von Yaki in deutscher Sprache."
  console.log Yaki(text, {language: 'de', tags: ['yaki']}).extract()
  # -> [ 'yaki', 'demonstriert', 'beispieltext', 'deutscher', 'sprache' ]
```

You can normalize and `clean()` an array of words, fragments or tags with Yaki.
```coffee
  fragments = ['(legend)', 'advanced.', 'MultiColor', '-> HTTP <-']
  console.log Yaki(fragments).clean()
  # -> [ 'legend', 'advanced', 'multicolor', 'http' ]
```

### ToDo

- [ ] Instead of transferring the heavy stopword-lists to the client, proxy client requests through
  a server method
- [x] Improve the algorithm to find multi-word phrases instead of just single words
- [x] Refactor the source code to improve readability and performance even further
- [ ] Add more test cases to ensure quality and enable better collaboration

### License

This code is licenced under the LGPL 3.0. Do whatever you want with this code, but I'd like to get improvements and bugfixes back. 