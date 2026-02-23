# frozen_string_literal: true

module LunrQuery
  # Porter Stemmer for English
  #
  # This is a Ruby port of Martin Porter's original C implementation.
  # See: http://www.tartarus.org/~martin/PorterStemmer
  # Updated with the some (?) of Snowball/Porter2 rules to match Lunr.js

  class PorterStemmer
    # Stem a word using the Porter algorithm
    #
    # @param word [String] Word to stem (must be lowercase)
    # @return [String] Stemmed word
    def self.stem(word)
      return word if word.length <= 2

      stemmer = new(word)
      stemmer.stem
      stemmer.to_s
    end

    def initialize(word)
      @b = word.dup  # buffer for word to be stemmed
      @k = word.length - 1  # offset to last character
      @k0 = 0  # offset to first character
      @j = 0  # general offset into the string
    end

    # Get the stemmed result
    def to_s
      @b[0..@k]
    end

    # Main stemming method
    def stem
      # Strings of length 1 or 2 don't go through the stemming process
      return if @k <= @k0 + 1

      step1ab
      if @k > @k0
        step1c
        step2
        step3
        step4
        step5
      end
    end

    private

    # cons(i) is true <=> b[i] is a consonant
    def cons(i)
      case @b[i]
      when 'a', 'e', 'i', 'o', 'u'
        false
      when 'y'
        i == @k0 ? true : !cons(i - 1)
      else
        true
      end
    end

    # m() measures the number of consonant sequences between k0 and j
    # if c is a consonant sequence and v a vowel sequence, and <..> indicates arbitrary presence,
    #
    #    <c><v>       gives 0
    #    <c>vc<v>     gives 1
    #    <c>vcvc<v>   gives 2
    #    <c>vcvcvc<v> gives 3
    #    ....
    def m
      n = 0
      i = @k0

      loop do
        return n if i > @j
        break unless cons(i)
        i += 1
      end

      i += 1

      loop do
        loop do
          return n if i > @j
          break if cons(i)
          i += 1
        end

        i += 1
        n += 1

        loop do
          return n if i > @j
          break unless cons(i)
          i += 1
        end

        i += 1
      end
    end

    # vowelinstem() is true <=> k0,...j contains a vowel
    def vowelinstem
      (@k0..@j).each do |i|
        return true unless cons(i)
      end
      false
    end

    # doublec(j) is true <=> j,(j-1) contain a double consonant
    def doublec(j)
      return false if j < @k0 + 1
      return false if @b[j] != @b[j - 1]
      cons(j)
    end

    # cvc(i) is true <=> i-2,i-1,i has the form consonant - vowel - consonant
    # and also if the second c is not w,x or y. this is used when trying to
    # restore an e at the end of a short word. e.g.
    #
    #    cav(e), lov(e), hop(e), crim(e), but
    #    snow, box, tray.
    def cvc(i)
      return false if i < @k0 + 2 || !cons(i) || cons(i - 1) || !cons(i - 2)
      ch = @b[i]
      return false if ch == 'w' || ch == 'x' || ch == 'y'
      true
    end

    # ends(s) is true <=> k0,...k ends with the string s
    def ends(s)
      length = s.length
      return false if s[length - 1] != @b[@k]  # tiny speed-up
      return false if length > @k - @k0 + 1

      if @b[@k - length + 1, length] != s
        false
      else
        @j = @k - length
        true
      end
    end

    # setto(s) sets (j+1),...k to the characters in the string s, readjusting k
    def setto(s)
      length = s.length
      @b[@j + 1, length] = s
      @k = @j + length
    end

    # r(s) is used further down
    def r(s)
      setto(s) if m > 0
    end

    # step1ab() gets rid of plurals and -ed or -ing. e.g.
    #
    #    caresses  ->  caress
    #    ponies    ->  poni
    #    ties      ->  ti
    #    caress    ->  caress
    #    cats      ->  cat
    #
    #    feed      ->  feed
    #    agreed    ->  agree
    #    disabled  ->  disable
    #
    #    matting   ->  mat
    #    mating    ->  mate
    #    meeting   ->  meet
    #    milling   ->  mill
    #    messing   ->  mess
    #
    #    meetings  ->  meet
    def step1ab
      if @b[@k] == 's'
        if ends('sses')
          @k -= 2
        elsif ends('ies')
          setto('i')
        elsif @b[@k - 1] != 's'
          @k -= 1
        end
      end

      if ends('eed')
        @k -= 1 if m > 0
      elsif (ends('ed') || ends('ing')) && vowelinstem
        @k = @j
        if ends('at')
          setto('ate')
        elsif ends('bl')
          setto('ble')
        elsif ends('iz')
          setto('ize')
        elsif doublec(@k)
          @k -= 1
          ch = @b[@k]
          @k += 1 if ch == 'l' || ch == 's' || ch == 'z'
        elsif m == 1 && cvc(@k)
          setto('e')
        end
      end
    end

    # step1c() turns terminal y to i when preceded by a non-vowel
    # that is not the first letter (Snowball/Porter2 rule, matches Lunr.js)
    def step1c
      @b[@k] = 'i' if ends('y') && @j > @k0 && cons(@j)
    end

    # step2() maps double suffices to single ones
    # so -ization ( = -ize plus -ation) maps to -ize etc. note that the
    # string before the suffix must give m() > 0
    def step2
      case @b[@k - 1]
      when 'a'
        r('ate') if ends('ational')
        r('tion') if ends('tional')
      when 'c'
        r('ence') if ends('enci')
        r('ance') if ends('anci')
      when 'e'
        r('ize') if ends('izer')
      when 'l'
        r('ble') if ends('bli')  # --DEPARTURE--
        # To match the published algorithm, replace this with:
        # r('able') if ends('abli')

        r('al') if ends('alli')
        r('ent') if ends('entli')
        r('e') if ends('eli')
        r('ous') if ends('ousli')
      when 'o'
        r('ize') if ends('ization')
        r('ate') if ends('ation')
        r('ate') if ends('ator')
      when 's'
        r('al') if ends('alism')
        r('ive') if ends('iveness')
        r('ful') if ends('fulness')
        r('ous') if ends('ousness')
      when 't'
        r('al') if ends('aliti')
        r('ive') if ends('iviti')
        r('ble') if ends('biliti')
      when 'g'
        r('log') if ends('logi')  # --DEPARTURE--
        # To match the published algorithm, delete this line
      end
    end

    # step3() deals with -ic-, -full, -ness etc. similar strategy to step2
    def step3
      case @b[@k]
      when 'e'
        r('ic') if ends('icate')
        r('') if ends('ative')
        r('al') if ends('alize')
      when 'i'
        r('ic') if ends('iciti')
      when 'l'
        r('ic') if ends('ical')
        r('') if ends('ful')
      when 's'
        r('') if ends('ness')
      end
    end

    # step4() takes off -ant, -ence etc., in context <c>vcvc<v>
    def step4
      case @b[@k - 1]
      when 'a'
        return unless ends('al')
      when 'c'
        return unless ends('ance') || ends('ence')
      when 'e'
        return unless ends('er')
      when 'i'
        return unless ends('ic')
      when 'l'
        return unless ends('able') || ends('ible')
      when 'n'
        return unless ends('ant') || ends('ement') || ends('ment') || ends('ent')
      when 'o'
        if ends('ion')
          return unless @j >= @k0 && (@b[@j] == 's' || @b[@j] == 't')
        else
          return unless ends('ou')
        end
      when 's'
        return unless ends('ism')
      when 't'
        return unless ends('ate') || ends('iti')
      when 'u'
        return unless ends('ous')
      when 'v'
        return unless ends('ive')
      when 'z'
        return unless ends('ize')
      else
        return
      end

      @k = @j if m > 1
    end

    # step5() removes a final -e if m() > 1, and changes -ll to -l if m() > 1
    def step5
      @j = @k

      if @b[@k] == 'e'
        a = m
        @k -= 1 if a > 1 || (a == 1 && !cvc(@k - 1))
      end

      @k -= 1 if @b[@k] == 'l' && doublec(@k) && m > 1
    end
  end

  # Pipeline function for stemming
  STEMMER = ->(token) {
    PorterStemmer.stem(token.downcase)
  }

  # Register stemmer as a pipeline function
  Pipeline.register_function('stemmer', STEMMER)
end
