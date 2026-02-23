module LunrQuery
  # Boolean set for document filtering
  #
  # Stores elements as hash keys for O(1) membership test.
  # Provides set operations: union, intersection.
  class Set
    attr_reader :elements, :length

    # Creates a new Set
    #
    # @param elements [Array] Optional array of elements
    def initialize(elements = nil)
      @elements = {}

      if elements
        @length = elements.length
        elements.each do |el|
          @elements[el] = true
        end
      else
        @length = 0
      end
    end

    # Check if set contains element
    #
    # @param object [Object] Element to check
    # @return [Boolean] True if element is in set
    def contains(object)
      !!@elements[object]
    end

    # Intersection with another set
    #
    # @param other [Set] Set to intersect with
    # @return [Set] New set containing common elements
    def intersect(other)
      return self if other.equal?(COMPLETE)
      return other if other.equal?(EMPTY)

      # Optimize: iterate over smaller set
      if @length < other.length
        a = self
        b = other
      else
        a = other
        b = self
      end

      intersection = []
      a.elements.keys.each do |element|
        intersection << element if b.elements.key?(element)
      end

      Set.new(intersection)
    end

    # Union with another set
    #
    # @param other [Set] Set to union with
    # @return [Set] New set containing all elements
    def union(other)
      return COMPLETE if other.equal?(COMPLETE)
      return self if other.equal?(EMPTY)

      Set.new(@elements.keys + other.elements.keys)
    end

    # Complete set - contains all elements
    COMPLETE = Object.new.tap do |obj|
      def obj.intersect(other)
        other
      end

      def obj.union(_other)
        self
      end

      def obj.contains(_object)
        true
      end
    end

    # Empty set - contains no elements
    EMPTY = Object.new.tap do |obj|
      def obj.intersect(_other)
        self
      end

      def obj.union(other)
        other
      end

      def obj.contains(_object)
        false
      end
    end
  end
end
