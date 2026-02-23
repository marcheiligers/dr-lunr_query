# v0.1.0 - 6 February 2026

* Initial release
* Load and query pre-built Lunr.js v2.3.9 indexes in DragonRuby
* Full query syntax: field scoping, presence modifiers (+/-), boosts (^)
* Wildcard matching: trailing (`drag*`), leading (`*gon`), and contained (`dr*on`)
* Fuzzy matching with Damerau-Levenshtein distance (`dragon~1`)
* Pipeline support: stemmer and stopword filter
* Porter Stemmer
* Automatic stemming of wildcard/fuzzy terms against stemmed indexes
* TF-IDF scoring with cosine similarity
* Position metadata for highlighting match locations
* Sample app: Astronaut search demo with biography, name, and mission matches

