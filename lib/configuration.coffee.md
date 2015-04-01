# Configuration
This file provides each language their special foible in calculating significance.

    Configuration = @Configuration =
    
## English
The english language has more shorter and lesser capitalized words. Asign also a stronger
weight on word entropy because the (most) short an simple word variations

      en:
        # Stemming with k-gramm (Yaki.stem)
        k: 4
        similarity: 0.6
        # Calculation (Yaki.calculate)
        entropieStrength: 3
        frequencyCoefficient: 1.0
        capitalizeBonus: 10
        akkronymBonus: 15
        positionCoefficient: 1.0
        tagBonus: 20
        # Word Combination (Yaki.combine)
        combinationOccurences: 2
        # Analyse (Yaki.analyse)
        minQuality: 3
        
## German
The german language has very long and more capitalized words. The words needs a
softer simmilarity level because more word variations (morphology).

      de:
        # Stemming with k-gramm (Yaki.stem)
        k: 4
        similarity: 0.45
        # Calculation (Yaki.calculate)
        entropieStrength: 2
        frequencyCoefficient: 1.0
        capitalizeBonus: 2
        akkronymBonus: 15
        positionCoefficient: 1.0
        tagBonus: 20
        # Word Combination (Yaki.combine)
        combinationOccurences: 2
        # Analyse (Yaki.analyse)
        minQuality: 5