# Copyright (c) [2015-2020] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

module Y3Storage
  #
  # Class to handle disk sizes in the MB/GB/TB range with readable output.
  #
  # Disk sizes are stored internally in bytes. Negative values are
  # allowed in principle but the special value -1 is reserved to mean
  # 'unlimited'.
  #
  # `DiskSize` objects are used through `Y3Storage` whenever a size has to be specified.
  # Notable exception here is class `Region` where several methods expect Integer arguments.
  # Like `Region#start`, `Region#length`, `Region#end`, and others.
  #
  # To get the size in bytes, use `#to_i`.
  #
  # Example:
  #     x = DiskSize.mib(6)   #=> <DiskSize 6.00 MiB (6291456)>
  #     x.to_i                #=> 6291456
  #
  class DiskSize
    include Comparable(DiskSize)

    # Defines a constant with a set of units and the corresponding class methods
    # to create `DiskSize` objects 
    macro define_units(constant_name, units)
      {{constant_name.id}} = {{units}}

      {% for unit in units %}
        # Creates a `DiskSize` object of *value* {{unit.id}} units.
        #
        # Example: these are 16 {{unit.id}}
        #     DiskSize.{{unit.downcase.id}}(16)
        def self.{{unit.downcase.id}}(value)
          DiskSize.new(calculate_bytes(value.to_f, {{unit}}))
        end
      {% end %}
    end

    define_units(UNITS, ["B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"])
    # International System of Units (SI)
    define_units(SI_UNITS, ["KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"])

    # Old units from AutoYaST (to be deprecated)
    DEPRECATED_UNITS = ["K", "M", "G"]
    UNLIMITED = "unlimited"

    # Return `DiskSize` in bytes.
    #
    # Example:
    #     x = DiskSize.kb(8)    #=> <DiskSize 7.81 KiB (8000)>
    #     x.to_i                #=> 8000
    #
    # Example: Unlimited size is represented internally by -1.
    #     x = DiskSize.unlimited    #=> <DiskSize <unlimited> (-1)>
    #     x.to_i                    #=> -1
    #
    getter size : Int64

    # Alias for `#size`
    def to_i
      size
    end
    
    # Alias for `#size`
    def to_storage_value
      size
    end

    # Constructor
    #
    # Accepts `Number`, `String` or `DiskSize` objects as initializers.
    # Raises `ArgumentError` if anything else is used as initializer
    #
    # See also `.parse`
    #
    # Example: Create 16 MiB DiskSize objects
    #     size1 = DiskSize.new(16*1024*1024)   #=> <DiskSize 16.00 MiB (16777216)>
    #     size2 = DiskSize.new("16 MiB")       #=> <DiskSize 16.00 MiB (16777216)>
    #     size3 = DiskSize.new(size1)          #=> <DiskSize 16.00 MiB (16777216)>
    #
    # Example: The default is size 0
    #     DiskSize.new                         #=> <DiskSize 0.00 B (0)>
    #
    # Example: You can have unlimited (infinite) size
    #     DiskSize.new("unlimited")            #=> <DiskSize <unlimited> (-1)>
    #
    def initialize(size = 0)
      size =
        if size.is_a?(Y3Storage::DiskSize)
          size.to_i
        elsif size.is_a?(::String)
          Y3Storage::DiskSize.parse(size).size
        elsif size.responds_to?(:round)
          size.round.to_i64
        end
      if size
        @size = size
      else
        raise ArgumentError.new("Cannot convert #{size.inspect} to DiskSize")
      end
    end

    # Create `DiskSize` object of unlimited size.
    #
    # Example: Unlimited (infinite) size
    #     DiskSize.unlimited   #=> <DiskSize <unlimited> (-1)>
    #
    def self.unlimited
      DiskSize.new(-1)
    end

    # Create `DiskSize` object of zero size.
    #
    # Example: Zero (0) size
    #   DiskSize.zero   #=> <DiskSize 0.00 B (0)>
    #
    def self.zero
      DiskSize.new(0)
    end

    # Total sum of all *sizes*, which must be an array of `DiskSize` objects.
    #
    # If the optional argument *rounding* is used, every size will be
    # rounded up (see `#ceil`).
    #
    # Example:
    #     x = DiskSize.KiB(1)       #=> <DiskSize 1.00 KiB (1024)>
    #     DiskSize.sum([x, x, x])   #=> <DiskSize 3.00 KiB (3072)>
    #
    def sum(sizes, *, rounding = nil)
      rounding ||= DiskSize.new(1)
      sizes.reduce(DiskSize.zero) { |sum, size| sum + size.ceil(rounding) }
    end

    # Create a `DiskSize` from a parsed string.
    #
    # If *legacy_units* is true, International System units are considered as base 2 units,
    # that is, MB is the same than MiB.
    #
    # Valid format:
    #
    # NUMBER [UNIT] [(COMMENT)] | unlimited
    #
    # A floating point number, optionally followed by a binary unit (e.g. 'GiB'),
    # optionally followed by a comment in parentheses (which is ignored).
    # Alternatively, the string 'unlimited' represents an infinite size.
    #
    # If UNIT is missing, 'B' (bytes) is assumed.
    #
    # Example:
    #     DiskSize.parse("42 GiB")              #=> <DiskSize 42.00 GiB (45097156608)>
    #     DiskSize.parse("42.00  GiB")          #=> <DiskSize 42.00 GiB (45097156608)>
    #     DiskSize.parse("42 GB")               #=> <DiskSize 39.12 GiB (42000000000)>
    #     DiskSize.parse("42GB")                #=> <DiskSize 39.12 GiB (42000000000)>
    #     DiskSize.parse("512")                 #=> <DiskSize 0.50 KiB (512)>
    #     DiskSize.parse("0.5 YiB (512 ZiB)")   #=> <DiskSize 0.50 YiB (604462909807314587353088)>
    #     DiskSize.parse("1024MiB(1 GiB)")      #=> <DiskSize 1.00 GiB (1073741824)>
    #     DiskSize.parse("unlimited")           #=> <DiskSize <unlimited> (-1)>
    #
    def self.parse(str, *, legacy_units = false)
      str = sanitize(str)
      return DiskSize.unlimited if str == UNLIMITED

      bytes = str_to_bytes(str, legacy_units: legacy_units)
      DiskSize.new(bytes)
    end

    # Alias for `.parse`
    def self.from_s(*args)
      parse(*args)
    end

    # Alias for `.parse`
    def self.from_human_string(*args)
      parse(*args)
    end

    # Ignores everything added in parentheses, so we can also parse the output of `#to_s`
    private def self.sanitize(str)
      str.gsub(/\(.*/, "").strip
    end

    private def self.str_to_bytes(str, *, legacy_units = false) : Int64
      number = number(str).to_f
      unit = unit(str)
      return number.to_i64 if unit.empty?

      calculate_bytes(number, unit, legacy_units: legacy_units)
    end

    private def self.number(str)
      scanned = str.scan(/^[+-]?\d+\.?\d*/)[0]?
      number = scanned ? scanned[0]? : nil
      raise ArgumentError.new("Not a number: #{str}") if number.nil?

      number
    end

    # Include all units for comparison
    ALL_UNITS = UNITS + DEPRECATED_UNITS + SI_UNITS

    private def self.unit(str)
      unit = str.gsub(number(str), "").strip
      return "" if unit.empty?

      unit = ALL_UNITS.find { |v| v.compare(unit, case_insensitive: true).zero? }
      raise ArgumentError.new("Bad disk size unit: #{str}") if unit.nil?

      unit
    end

    private def self.calculate_bytes(number, unit, *, legacy_units = false)
      if exp = UNITS.index(unit)
        base = 1024_u64
      elsif exp = SI_UNITS.index(unit)
        base = 1000_u64
        exp += 1
      elsif exp = DEPRECATED_UNITS.index(unit)
        base = 1000_u64
        exp += 1
      else
        raise ArgumentError.new("Bad disk size unit: #{unit}")
      end
      base = 1024_u64 if legacy_units
      (number * base**exp).to_i64
    end

    #
    # Operators
    #

    # Adds a `DiskSize` object and another object. The other object must
    # be acceptable to `.new`.
    #
    # *other* can be a `Number`, `String` or `DiskSize`.
    #
    # Example:
    #     x = DiskSize.mib(3)      #=> <DiskSize 3.00 MiB (3145728)>
    #     y = DiskSize.kb(1)       #=> <DiskSize 0.98 KiB (1000)>
    #     x + 100                  #=> <DiskSize 3.00 MiB (3145828)>
    #     x + "1 MiB"              #=> <DiskSize 4.00 MiB (4194304)>
    #     x + y                    #=> <DiskSize 3.00 MiB (3146728)>
    #     x + DiskSize.unlimited   #=> <DiskSize <unlimited> (-1)>
    #     x + "unlimited"          #=> <DiskSize <unlimited> (-1)>
    #
    def +(other)
      return DiskSize.unlimited if any_operand_unlimited?(other)

      DiskSize.new(@size + DiskSize.new(other).to_i)
    end

    # Substracts a `DiskSize` object and another object. The other object
    # must be acceptable to `.new`.
    #
    # *other* can be a `Number`, `String` or `DiskSize`.
    #
    # Example:
    #     x = DiskSize.mib(3)      #=> <DiskSize 3.00 MiB (3145728)>
    #     y = DiskSize.kb(1)       #=> <DiskSize 0.98 KiB (1000)>
    #     x - 100                  #=> <DiskSize 3.00 MiB (3145628)>
    #     x - "1 MiB"              #=> <DiskSize 2.00 MiB (2097152)>
    #     x - y                    #=> <DiskSize 3.00 MiB (3144728)>
    #     # sizes can be negative
    #     y - x                    #=> <DiskSize -3.00 MiB (-3144728)>
    #     # but there's no "-unlimited"
    #     x - DiskSize.unlimited   #=> <DiskSize <unlimited> (-1)>
    #
    def -(other)
      return DiskSize.unlimited if any_operand_unlimited?(other)

      DiskSize.new(@size - DiskSize.new(other).to_i)
    end

    # The remainder dividing a `DiskSize` object by another object. The
    # other object must be acceptable to `.new`.
    #
    # *other* can be a `Number`, `String` or `DiskSize`.
    #
    # Example:
    #   x = DiskSize.mib(3)   #=> <DiskSize 3.00 MiB (3145728)>
    #   y = DiskSize.kb(1)    #=> <DiskSize 0.98 KiB (1000)>
    #   x % 100               #=> <DiskSize 28.00 B (28)>
    #   X % "1 MB"            #=> <DiskSize 142.31 KiB (145728)>
    #   x % y                 #=> <DiskSize 0.71 KiB (728)>
    #
    def %(other)
      return DiskSize.unlimited if any_operand_unlimited?(other)

      DiskSize.new(@size % DiskSize.new(other).to_i)
    end

    # Multiply a `DiskSize` object by a `Number` object.
    #
    # Example:
    #     x = DiskSize.mib(1)      #=> <DiskSize 1.00 MiB (1048576)>
    #     x * 3                    #=> <DiskSize 3.00 MiB (3145728)>
    #
    def *(other)
      raise ArgumentError.new("Unexpected #{other.class}; expected Number value") if !other.is_a?(Number)

      return DiskSize.unlimited if unlimited?

      DiskSize.new(@size * other)
    end

    # Divide a `DiskSize` object by a `Number` object.
    #
    # Example:
    #     x = DiskSize.mib(1)      #=> <DiskSize 1.00 MiB (1048576)>
    #     x / 3                    #=> <DiskSize 341.33 KiB (349525)>
    #
    def /(other)
      raise ArgumentError.new("Unexpected #{other.class}; expected Number value") if !other.is_a?(Number)

      return DiskSize.unlimited if unlimited?

      DiskSize.new(@size.to_f / other)
    end

    #
    # Other methods
    #

    # Test if `DiskSize` is unlimited.
    #
    # Example:
    #     x = DiskSize.GiB(10)   #=> <DiskSize 10.00 GiB (10737418240)>
    #     x.unlimited?           #=> false
    def unlimited?
      @size == -1
    end

    # Test if `DiskSize` is zero.
    #
    # Example:
    #     x = DiskSize.GiB(10)   #=> <DiskSize 10.00 GiB (10737418240)>
    #     x.zero?                #=> false
    def zero?
      @size == 0
    end

    # Test if `DiskSize` (amount of bytes) is power of certain value
    #
    # Example:
    #     x = DiskSize.kib(4)   #=> <DiskSize 4.00 KiB (4096)>
    #     x.power_of?(2)        #=> true
    #     x.power_of?(10)       #=> false
    #
    #     x = DiskSize.kb(100)  #=> <DiskSize 97.66 KiB (100000)>
    #     x.power_of?(2)        #=> false
    #     x.power_of?(10)       #=> true
    def power_of?(exp)
      return false if unlimited?

      (Math.log(size, exp) % 1).zero?
    end

    # Compare two `DiskSize` objects.
    #
    # NOTE: The Comparable mixin will get us operators < > <= >= == != with this.
    #
    # Example:
    #     x = DiskSize.gib(10)   #=> <DiskSize 10.00 GiB (10737418240)>
    #     y = DiskSize.gb(10)    #=> <DiskSize 9.31 GiB (10000000000)>
    #     x <=> y                #=> 1
    #     x > y                  #=> true
    def <=>(other : DiskSize)
      if other.unlimited?
        unlimited? ? 0 : -1
      elsif unlimited?
        1
      else
        size <=> other.size
      end
    end

    # Round up the size to the next value that is divisible by
    # a given size. Return the same value if it's already divisible.
    #
    # Example:
    #     x = DiskSize.kib(10)   #=> <DiskSize 10.00 KiB (10240)>
    #     y = DiskSize.kb(1)     #=> <DiskSize 0.98 KiB (1000)>
    #     x.ceil(y)              #=> <DiskSize 10.74 KiB (11000)>
    def ceil(unit_size)
      new_size = floor(unit_size)
      new_size = new_size + unit_size if new_size != self
      new_size
    end

    # Round down the size to the previous value that is divisible
    # by a given size. Return the same value if it's already divisible.
    #
    # Example:
    #     x = DiskSize.kib(10)   #=> <DiskSize 10.00 KiB (10240)>
    #     y = DiskSize.kb(1)     #=> <DiskSize 0.98 KiB (1000)>
    #     x.floor(y)             #=> <DiskSize 9.77 KiB (10000)>
    def floor(unit_size)
      return DiskSize.new(@size) unless can_be_rounded?(unit_size)

      modulo = @size % unit_size.to_i
      DiskSize.new(@size - modulo)
    end

    # Human-readable string. That is, represented in the biggest unit ("MiB",
    # "GiB", ...) that makes sense, even if it means losing some precision.
    #
    # *rounding_method* can have any of the following values:
    #
    #   - `:round` - the default
    #   - `:floor` (available as `#human_floor`) - If we have 4.999 GiB of space,
    #   and ask the user how much of that should be used, prefilling the "Size"
    #   widget with the maximum rounded up to "5.00 GiB" it will then fail
    #   validation (checking that the entered value fits in the available space)
    #   We must round down.
    #   - `:ceil` (available as `#human_ceil`) - (This seems unnecessary because
    #   actual minimum sizes have few significant digits, but we provide it for
    #   symmetry)
    #
    # Example:
    #     x = DiskSize.kb(1)   #=> <DiskSize 0.98 KiB (1000)>
    #     x.to_human_string    #=> "0.98 KiB"
    #
    #     smaller = DiskSize.new(4095)  #=> <DiskSize 4.00 KiB (4095)>
    #     smaller.to_human_string       #=> "4.00 KiB"
    #     smaller.human_floor           #=> "3.99 KiB"
    #
    #     larger = DiskSize.new(4097)   #=> <DiskSize 4.00 KiB (4097)>
    #     larger.to_human_string        #=> "4.00 KiB"
    #     larger.human_ceil             #=> "4.01 KiB"
    #
    def to_human_string(rounding_method = :round)
      float, unit_s = human_string_components
      return "unlimited" unless float.is_a?(Float)

      rounded = rounded(float * 100, rounding_method) / 100.0
      # A plain "#{rounded} #{unit_s}" would not keep trailing zeros
      "%.2f %s" % [rounded, unit_s]
    end

    # Method implemented because we don't have Ruby's #send, althought in theory
    # there is a way to emulate it to some extend.
    # https://github.com/crystal-lang/crystal/wiki/MetaProgramming-Help
    private def rounded(number, meth)
      case meth
      when :round
        number.round
      when :ceil
        number.ceil
      when :floor
        number.floor
      else
        number
      end
    end

    # Same that `to_human_string(:floor)`
    def human_floor
      to_human_string(rounding_method: :floor)
    end

    # Same that `to_human_string(:ceil)`
    def human_ceil
      to_human_string(rounding_method: :ceil)
    end

    # Exact value + human readable in parentheses (if the latter makes sense).
    #
    # The result can be passed to `new` or `parse` to get a `DiskSize` object of the same size.
    #
    # Example:
    #     x = DiskSize.kb(1)     #=> <DiskSize 0.98 KiB (1000)>
    #     x.to_s                 #=> "1000 B (0.98 KiB)"
    #     DiskSize.new(x.to_s)   #=> "1000 B (0.98 KiB)"
    def to_s
      return "unlimited" if unlimited?

      size1, unit1 = human_string_components
      size2, unit2 = string_components
      v1 = "%.2f %s" % [size1, unit1]
      v2 = "#{(size2 % 1 == 0) ? size2.to_i : size2} #{unit2}"
      # if both units are the same, just use exact value
      (unit1 == unit2) ? v2 : "#{v2} (#{v1})"
    end

    # Human readable + exact values in brackets for debugging or logging.
    #
    # Example:
    #     x = DiskSize.KB(1)   #=> <DiskSize 0.98 KiB (1000)>
    #     x.inspect            #=> "<DiskSize 0.98 KiB (1000)>"
    def inspect
      return "<DiskSize <unlimited> (-1)>" if unlimited?

      "<DiskSize #{to_human_string} (#{to_i})>"
    end

    # Return 'true' if either self or other is unlimited.
    #
    private def any_operand_unlimited?(other)
      return true if unlimited?
      return true if other.responds_to?(:unlimited?) && other.unlimited?

      other.responds_to?(:to_s) && other.to_s == "unlimited"
    end

    # Checks whether makes sense to round the value to the given size
    private def can_be_rounded?(unit_size)
      return false if unit_size.unlimited? || unit_size.zero? || unit_size.to_i == 1

      !unlimited? && !zero?
    end

    # Returns numeric size and unit ("MiB", "GiB", ...) in human-readable form
    private def human_string_components
      return [UNLIMITED, ""] if @size == -1

      unit_index = 0
      # prefer 0.50 MiB over 512 KiB
      size2 = @size * 2

      while size2.abs >= 1024.0 && unit_index < UNITS.size - 1
        size2 /= 1024.0
        unit_index += 1
      end
      [size2 / 2.0, UNITS[unit_index]] # FIXME: Make unit translatable
    end

    # Returns numeric size and unit ("MiB", "GiB", ...).
    # Unlike `#human_string_components`, always return the exact value.
    private def string_components
      return [UNLIMITED, ""] if @size == -1

      unit_index = 0
      # allow half values
      size2 = @size * 2

      while size2 != 0 && (size2 % 1024) == 0 && unit_index < UNITS.size - 1
        size2 /= 1024
        unit_index += 1
      end
      [size2 / 2.0, UNITS[unit_index]]
    end
  end
end
