# Composition: Ranges
# Defines spans of identifiers for areas, categories, and valid ID spaces
#
# COMPOSITION LAYER: Builds on identifiers to define contiguous ranges.
#
# Ranges represent spans of identifiers with inclusive bounds:
# - Johnny Decimal areas: [10 0] - [19 99] (area 10-19, all categories/items)
# - Version ranges: [1 0 0] - [2 0 0] (v1.x.x through v2.0.0)
# - Open-ended ranges: [10 0] - null (10+ everything from 10 onwards)
#
# API:
#   mk = {start, end} -> Range
#   contains = Range -> Identifier -> Bool (is ID in range?)
#   containing = Range -> Range -> Bool (does range1 contain range2?)
#   validate = Range -> Bool (is range well-formed?)
#
# Examples:
#   # Johnny Decimal area 10-19
#   area = ranges.mk {start = [10 0]; end = [19 99];};
#   ranges.contains area [15 5]   => true
#   ranges.contains area [20 0]   => false
#   ranges.validate area          => true

{
  lib,
  primitives,
}: let
  # Compare two identifiers using lexicographic ordering
  #
  # Compares element-by-element from left to right. First differing
  # element determines the result. If all compared elements are equal,
  # the shorter identifier is considered "less than".
  #
  # Algorithm:
  #   1. Compare corresponding elements until difference found or end reached
  #   2. If all equal, compare lengths
  #
  # Returns: -1 (a < b), 0 (a == b), 1 (a > b)
  #
  # Examples:
  #   compareIdentifiers [10 5] [10 10]  => -1 (5 < 10)
  #   compareIdentifiers [10 5] [10 5]   => 0  (equal)
  #   compareIdentifiers [10 5] [10 1]   => 1  (5 > 1)
  #   compareIdentifiers [10] [10 5]     => -1 (shorter < longer when equal)
  compareIdentifiers = a: b: let
    lenA = builtins.length a;
    lenB = builtins.length b;
    minLen = if lenA < lenB then lenA else lenB;

    # Compare element by element
    go = idx:
      if idx >= minLen
      then
        # All compared elements equal, check lengths
        if lenA < lenB
        then -1
        else if lenA > lenB
        then 1
        else 0
      else let
        valA = builtins.elemAt a idx;
        valB = builtins.elemAt b idx;
      in
        if valA < valB
        then -1
        else if valA > valB
        then 1
        else go (idx + 1); # Equal, continue
  in
    go 0;
in {
  # Create a range with inclusive bounds
  #
  # Defines a contiguous span of identifiers from start to end (inclusive).
  # End can be null for open-ended ranges (everything >= start).
  #
  # Parameters:
  #   - start: Identifier (list of ints) marking range start (inclusive)
  #   - end: Identifier (list of ints) or null for open-ended
  #
  # Returns: Range object for use with contains/containing/validate
  #
  # Examples:
  #   mk {start = [10 0]; end = [19 99];}  # JD area 10-19
  #   mk {start = [10 0]; end = null;}     # Open-ended: 10+
  mk = {
    start,
    end,
  }: {
    inherit start end;
  };

  # Check if an identifier falls within a range
  #
  # Tests if an identifier is between start and end (inclusive).
  # For open-ended ranges (end == null), only checks start bound.
  #
  # Uses lexicographic comparison: [10 5] is between [10 0] and [19 99].
  #
  # Returns: true if start <= identifier <= end (or end is null)
  #
  # Examples:
  #   area = mk {start = [10 0]; end = [19 99];};
  #   contains area [15 5]   => true  (within bounds)
  #   contains area [20 0]   => false (outside bounds)
  #   contains area [10 0]   => true  (start is inclusive)
  #   contains area [19 99]  => true  (end is inclusive)
  contains = range: identifier: let
    start = range.start;
    end = range.end;

    # Compare identifier with start
    cmpStart = compareIdentifiers identifier start;

    # Compare identifier with end (if end exists)
    cmpEnd =
      if end == null
      then -1 # Open-ended, always "less than" end
      else compareIdentifiers identifier end;
  in
    # identifier >= start AND identifier <= end (or end is null)
    cmpStart >= 0 && cmpEnd <= 0;

  # Check if one range fully contains another range
  #
  # Tests if the outer range completely encompasses the inner range.
  # Both start and end of inner must be within outer's bounds.
  #
  # Algorithm:
  #   1. Check outer.start <= inner.start
  #   2. Check inner.end <= outer.end
  #   3. Return true only if both conditions hold
  #
  # Special cases:
  #   - If outer is open-ended (end == null), it contains all inner ends
  #   - If inner is open-ended but outer isn't, returns false
  #
  # Returns: true if outer fully contains inner
  #
  # Examples:
  #   outer = mk {start = [10 0]; end = [29 99];};
  #   inner = mk {start = [15 0]; end = [19 99];};
  #   containing outer inner  => true
  #
  #   # Overlapping but not containing
  #   range1 = mk {start = [10 0]; end = [19 99];};
  #   range2 = mk {start = [15 0]; end = [25 0];};
  #   containing range1 range2  => false
  containing = outer: inner: let
    outerStart = outer.start;
    outerEnd = outer.end;
    innerStart = inner.start;
    innerEnd = inner.end;

    # Check if outer.start <= inner.start
    startContained = compareIdentifiers outerStart innerStart <= 0;

    # Check if inner.end <= outer.end
    endContained =
      if outerEnd == null
      then true # Outer is open-ended, contains everything
      else if innerEnd == null
      then false # Inner is open-ended, outer must be too (handled above)
      else compareIdentifiers innerEnd outerEnd <= 0;
  in
    startContained && endContained;

  # Validate that a range is well-formed
  #
  # Checks if the range makes logical sense: start must come before or
  # equal to end in lexicographic order.
  #
  # A range where end < start is invalid (empty range).
  # Open-ended ranges (end == null) are always valid.
  #
  # Returns: true if start <= end (or end is null), false otherwise
  #
  # Examples:
  #   validate (mk {start = [10 0]; end = [19 99];})  => true
  #   validate (mk {start = [19 99]; end = [10 0];})  => false (inverted!)
  #   validate (mk {start = [10 0]; end = null;})     => true  (open-ended)
  validate = range: let
    start = range.start;
    end = range.end;
  in
    if end == null
    then true # Open-ended ranges always valid
    else compareIdentifiers start end <= 0;
}
