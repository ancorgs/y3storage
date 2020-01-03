require "./spec_helper"

describe Y3Storage::DiskSize do
  described_class = Y3Storage::DiskSize
  zero = Y3Storage::DiskSize.zero
  unlimited = Y3Storage::DiskSize.unlimited
  one_byte = Y3Storage::DiskSize.new(1)

  # We have nothing equivalent to Y2Storage::Refinements::SizeCasts, let's try
  # this as another way to shorten definition of sizes
  s = described_class

  describe ".new" do
    context "when no param is passed" do
      it "creates a disk size of 0 bytes" do
        described_class.new.size.should eq(0)
      end
    end

    context "when a number is passed" do
      context "and is a natural number" do
        it "creates a disk size with this number of bytes" do
          described_class.new(5).size.should eq(5)
        end
      end

      context "and is a floating point number" do
        it "creates a disk size with a rounded number of bytes" do
          described_class.new(5.6).size.should eq(6)
          described_class.new(5.4).size.should eq(5)
        end
      end
    end

    context "when a string is passed" do
      it "creates a disk size with the number of bytes represented by the string" do
        described_class.new("5").size.should eq(5)
        described_class.new("15 KB").size.should eq(15 * 1000)
        described_class.new("15 MiB").size.should eq(15 * 1024**2)
        described_class.new("23 TiB").size.should eq(23_u64 * 1024_u64**4)
        described_class.new("23.2 KiB").size.should eq((23.2 * 1024).to_i)
      end
    end
  end

  describe ".b" do
    it "creates a disk size from a number of bytes" do
      described_class.b(5).size.should eq(5)
    end
  end

  describe ".kib" do
    it "creates a disk size from a number of KiB" do
      described_class.kib(5).size.should eq(5 * 1024)
    end
  end

  describe ".mib" do
    it "creates a disk size from a number of MiB" do
      described_class.mib(5).size.should eq(5 * 1024**2)
    end
  end

  describe ".gib" do
    it "creates a disk size from a number of GiB" do
      described_class.gib(5).size.should eq(5_i64 * 1024_i64**3)
    end
  end

  describe ".tib" do
    it "creates a disk size from a number of TiB" do
      described_class.tib(5).size.should eq(5_i64 * 1024_i64**4)
    end
  end

  describe ".pib" do
    it "creates a disk size from a number of PiB" do
      described_class.pib(5).size.should eq(5_i64 * 1024_i64**5)
    end
  end

  describe ".eib" do
    it "creates a disk size from a number of EiB" do
      described_class.eib(5).size.should eq(5_i64 * 1024_i64**6)
    end
  end

  # describe ".zib" do
  #   it "creates a disk size from a number of ZiB" do
  #     described_class.zib(5).size.should eq(5 * 1024**7)
  #   end
  # end

  # describe ".yib" do
  #   it "creates a disk size from a number of YiB" do
  #     described_class.yib(5).size.should eq(5 * 1024**8)
  #   end
  # end

  describe ".kb" do
    it "creates a disk size from a number of KB" do
      described_class.kb(5).size.should eq(5 * 1000)
    end
  end

  describe ".mb" do
    it "creates a disk size from a number of MB" do
      described_class.mb(5).size.should eq(5 * 1000**2)
    end
  end

  describe ".gb" do
    it "creates a disk size from a number of GB" do
      described_class.gb(5).size.should eq(5_i64 * 1000_i64**3)
    end
  end

  describe ".tb" do
    it "creates a disk size from a number of TB" do
      described_class.tb(5).size.should eq(5_i64 * 1000_i64**4)
    end
  end

  describe ".pb" do
    it "creates a disk size from a number of PB" do
      described_class.pb(5).size.should eq(5_i64 * 1000_i64**5)
    end
  end

  describe ".eb" do
    it "creates a disk size from a number of EB" do
      described_class.eb(5).size.should eq(5_i64 * 1000_i64**6)
    end
  end

  # describe ".zb" do
  #   it "creates a disk size from a number of ZB" do
  #     described_class.zb(5).size.should eq(5 * 1000**7)
  #   end
  # end

  # describe ".yb" do
  #   it "creates a disk size from a number of YB" do
  #     described_class.yb(5).size.should eq(5 * 1000**8)
  #   end
  # end

  describe ".to_human_string" do
    context "when has a specific size" do
      it("returns human-readable string represented in the biggest possible unit") do
        described_class.b(5 * 1024**0).to_human_string.should eq("5.00 B")
        described_class.b(5 * 1024**1).to_human_string.should eq("5.00 KiB")
        described_class.b(5_i64 * 1024_i64**3).to_human_string.should eq("5.00 GiB")
        described_class.b(5_i64 * 1024_i64**4).to_human_string.should eq("5.00 TiB")
        # described_class.b(5 * 1024**7).to_human_string.should eq("5.00 ZiB")
      end
    end

    context "when has unlimited size" do
      it "returns 'unlimited'" do
        described_class.unlimited.to_human_string.should eq("unlimited")
      end
    end
  end

  describe ".human_floor" do
    context "when it has a specific size" do
      it("returns human-readable string not exceeding the actual size") do
        described_class.b(4095 * 1024**0).human_floor.should eq("3.99 KiB")
        described_class.b(4095_i64 * 1024_i64**3).human_floor.should eq("3.99 TiB")
      end
    end

    context "when it has unlimited size" do
      it "returns 'unlimited'" do
        described_class.unlimited.human_floor.should eq("unlimited")
      end
    end
  end

  describe ".human_ceil" do
    context "when it has a specific size" do
      it("returns human-readable string not exceeding the actual size") do
        described_class.b(4097 * 1024**0).human_ceil.should eq("4.01 KiB")
        described_class.b(4097_i64 * 1024_i64**3).human_ceil.should eq("4.01 TiB")
      end
    end

    context "when it has unlimited size" do
      it "returns 'unlimited'" do
        described_class.unlimited.human_ceil.should eq("unlimited")
      end
    end
  end

  describe "#+" do
    it "should accept addition of another DiskSize" do
      disk_size = Y3Storage::DiskSize.gib(10) + Y3Storage::DiskSize.gib(20)
      disk_size.to_i.should eq 30_i64 * 1024_i64**3
    end
    it "should accept addition of an int" do
      disk_size = Y3Storage::DiskSize.mib(20) + 512
      disk_size.to_i.should eq 20 * 1024**2 + 512
    end
    it "should accept addition of a string with a valid disk size spec" do
      disk_size = Y3Storage::DiskSize.mib(20) + "512 KiB"
      disk_size.to_i.should eq 20 * 1024**2 + 512 * 1024
    end
    it "should refuse addition of a random string" do
      expect_raises(ArgumentError) { Y3Storage::DiskSize.mib(20) + "Foo Bar" }
    end
    it "should refuse addition of another type" do
      expect_raises(ArgumentError) { Y3Storage::DiskSize.mib(20) + true }
    end
  end

  describe "#-" do
    it "should accept subtraction of another DiskSize" do
      disk_size = Y3Storage::DiskSize.gib(20) - Y3Storage::DiskSize.gib(5)
      disk_size.to_i.should eq 15_i64 * 1024_i64**3
    end
    it "should accept subtraction of an int" do
      disk_size = Y3Storage::DiskSize.kib(3) - 1024
      disk_size.to_i.should eq 2048
    end
    it "should accept subtraction of a string with a valid disk size spec" do
      disk_size = Y3Storage::DiskSize.mib(20) - "512 KiB"
      disk_size.to_i.should eq 20 * 1024**2 - 512 * 1024
    end
    it "should refuse subtraction of a random string" do
      expect_raises(ArgumentError) { Y3Storage::DiskSize.mib(20) - "Foo Bar" }
    end
    it "should refuse subtraction of another type" do
      expect_raises(ArgumentError) { Y3Storage::DiskSize.mib(20) - true }
    end
  end

  describe "#%" do
    it "should accept another DiskSize" do
      disk_size = Y3Storage::DiskSize.kib(2) % Y3Storage::DiskSize.kb(1)
      disk_size.to_i.should eq 48
    end
    it "should accept an int" do
      disk_size = Y3Storage::DiskSize.kib(4) % 1000
      disk_size.to_i.should eq 96
    end
    it "should accept a string with a valid disk size spec" do
      disk_size = Y3Storage::DiskSize.mib(20) % "100 KB"
      disk_size.to_i.should eq 20 * 1024**2 % (100 * 1000)
    end
    it "should refuse a random string" do
      expect_raises(ArgumentError) { Y3Storage::DiskSize.mib(20) % "Foo Bar" }
    end
    it "should refuse another type" do
      expect_raises(ArgumentError) { Y3Storage::DiskSize.mib(20) % true }
    end
  end

  describe "#*" do
    it "should accept multiplication with an int" do
      disk_size = Y3Storage::DiskSize.mib(12) * 3
      disk_size.to_i.should eq 12 * 1024**2 * 3
    end
    it "should accept multiplication with a float" do
      disk_size = Y3Storage::DiskSize.b(10) * 4.5
      disk_size.to_i.should eq 45
    end
    it "should refuse multiplication with a string" do
      expect_raises(ArgumentError) { Y3Storage::DiskSize.mib(12) * "100" }
    end
    it "should refuse multiplication with another DiskSize" do
      expect_raises(ArgumentError) { Y3Storage::DiskSize.mib(12) * Y3Storage::DiskSize.mib(3) }
    end
  end

  describe "#/" do
    it "should accept division by an int" do
      disk_size = Y3Storage::DiskSize.mib(12) / 3
      disk_size.to_i.should eq 12 / 3 * 1024**2
    end
    it "should accept division by a float" do
      disk_size = Y3Storage::DiskSize.b(10) / 2.5
      disk_size.to_i.should eq 4
    end
    it "should refuse division by a string" do
      expect_raises(ArgumentError) { Y3Storage::DiskSize.mib(12) / "100" }
    end
    it "should refuse division by another type" do
      expect_raises(ArgumentError) { Y3Storage::DiskSize.mib(20) / true }
    end
    # DiskSize / DiskSize should be possible, returning an int,
    # but we haven't needed it so far.
  end

  describe "arithmetic operations with unlimited and DiskSize" do
    unlimited = Y3Storage::DiskSize.unlimited
    disk_size = Y3Storage::DiskSize.gib(42)
    it "should return unlimited" do
      (unlimited + disk_size).should eq unlimited
      (disk_size + unlimited).should eq unlimited
      (unlimited - disk_size).should eq unlimited
      (disk_size - unlimited).should eq unlimited
      # DiskSize * DiskSize and DiskSize / DiskSize are undefined
    end
  end

  describe "arithmetic operations with unlimited and a number" do
    unlimited = Y3Storage::DiskSize.unlimited
    number    = 7
    it "should return unlimited" do
      (unlimited + number).should eq unlimited
      (unlimited - number).should eq unlimited
      (unlimited * number).should eq unlimited
      (unlimited / number).should eq unlimited
    end
  end

  describe "#power_of?" do
    context "when the number of bytes is power of the given value" do
      it "returns true" do
        s.mib(8).power_of?(2).should eq true
        s.kb(100).power_of?(10).should eq true
      end
    end

    context "when the number of bytes is not power of the given value" do
      it "returns false" do
        s.mib(8).power_of?(10).should eq false
        s.kb(100).power_of?(2).should eq false
      end
    end

    context "when the size is zero" do
      it "returns false" do
        described_class.zero.power_of?(0).should eq false
        described_class.zero.power_of?(1).should eq false
        described_class.zero.power_of?(2).should eq false
        described_class.zero.power_of?(5).should eq false
      end
    end

    context "when the size is unlimited" do
      disk_size = unlimited

      it "returns false" do
        described_class.unlimited.power_of?(0).should eq false
        described_class.unlimited.power_of?(1).should eq false
        described_class.unlimited.power_of?(2).should eq false
        described_class.unlimited.power_of?(5).should eq false
      end
    end
  end

  describe "comparison" do
    disk_size1 = Y3Storage::DiskSize.gib(24)
    disk_size2 = Y3Storage::DiskSize.gib(32)
    disk_size3 = Y3Storage::DiskSize.gib(32)
    it "operator < should compare correctly" do
      (disk_size1 < disk_size2).should eq true
      (disk_size2 < disk_size3).should eq false
    end
    it "operator > should compare correctly" do
      (disk_size1 > disk_size2).should eq false
      (disk_size2 > disk_size3).should eq false
    end
    it "operator == should compare correctly" do
      (disk_size2 == disk_size3).should eq true
    end
    it "operator != should compare correctly" do
      (disk_size1 != disk_size2).should eq true
    end
    it "operator <= should compare correctly" do
      (disk_size2 <= disk_size3).should eq true
    end
    it "operator >= should compare correctly" do
      (disk_size2 >= disk_size3).should eq true
    end
    # Comparing with an integer (#to_i) seems to make sense,
    # but we haven't needed it so far.
  end

  describe "comparison with unlimited" do
    unlimited = Y3Storage::DiskSize.unlimited
    disk_size = Y3Storage::DiskSize.gib(42)
    it "should compare any disk size correctly with unlimited" do
      disk_size.should be < unlimited
      disk_size.should_not be > unlimited
      disk_size.should_not eq unlimited
    end
    it "should compare unlimited correctly with any disk size" do
      unlimited.should be > disk_size
      unlimited.should_not be < disk_size
      unlimited.should_not eq disk_size
    end
    it "should compare unlimited correctly with unlimited" do
      unlimited.should_not be > unlimited
      unlimited.should_not be < unlimited
      unlimited.should eq unlimited
    end
  end

  describe ".parse" do
    it "should work with just a number" do
      described_class.parse("0").to_i.should eq(0)
      described_class.parse("7").to_i.should eq(7)
      described_class.parse("7.00").to_i.should eq(7)
    end

    it "should also accept signed numbers" do
      described_class.parse("-12").to_i.should eq(-12)
      described_class.parse("+12").to_i.should eq(+12)
    end

    it "should work with integer and unit" do
      described_class.parse("42 GiB").to_i.should eq(42_i64 * 1024_i64**3)
      described_class.parse("-42 GiB").to_i.should eq(-42_i64 * 1024_i64**3)
    end

    it "should work with float and unit" do
      described_class.parse("43.00 GiB").to_i.should eq(43_i64 * 1024_i64**3)
      described_class.parse("-43.00 GiB").to_i.should eq(-43_i64 * 1024_i64**3)
    end

    it "should work with non-integral numbers and unit" do
      described_class.parse("43.456 GB").to_i.should eq(43.456 * 1000**3)
      described_class.parse("-43.456 GB").to_i.should eq(-43.456 * 1000**3)
    end

    it "should work with integer and unit without space between them" do
      described_class.parse("10MiB").to_i.should eq(10 * 1024**2)
    end

    it "should work with float and unit without space between them" do
      described_class.parse("10.00MiB").to_i.should eq(10 * 1024**2)
    end

    it "should tolerate more embedded whitespace" do
      described_class.parse("44   MiB").to_i.should eq(44 * 1024**2)
    end

    it "should tolerate more surrounding whitespace" do
      described_class.parse("   45   TiB  ").to_i.should eq(45_i64 * 1024_i64**4)
      described_class.parse("  46   ").to_i.should eq(46)
    end

    it "should accept \"unlimited\"" do
      described_class.parse("unlimited").to_i.should eq(-1)
    end

    it "should accept \"unlimited\" with surrounding whitespace" do
      described_class.parse("  unlimited ").to_i.should eq(-1)
    end

    it "should accept International System units" do
      described_class.parse("10 KB").to_i.should eq(10 * 1000)
      described_class.parse("10 MB").to_i.should eq(10 * 1000**2)
    end

    it "should accept deprecated units" do
      described_class.parse("10 K").to_i.should eq(10_i64 * 1000_i64)
      described_class.parse("10 M").to_i.should eq(10_i64 * 1000_i64**2)
      described_class.parse("10 G").to_i.should eq(10_i64 * 1000_i64**3)
    end

    it "should not be case sensitive" do
      described_class.parse("10k").to_i.should eq(10 * 1000)
      described_class.parse("10Kb").to_i.should eq(10 * 1000)
    end

    context "when using the legacy_unit flag" do
      legacy = true

      it "considers international system units to be power of two" do
        described_class.parse("10 MB", legacy_units: legacy).size.should eq(10 * 1024**2)
      end

      it "considers deprecated units to be power of two" do
        described_class.parse("10 M", legacy_units: legacy).to_i.should eq(10 * 1024**2)
      end

      it "reads units that are power of two in the usual way" do
        described_class.parse("10 MiB", legacy_units: legacy).size.should eq(10 * 1024**2)
      end
    end

    it "should accept #to_s output" do
      # described_class.parse(described_class.gib(42).to_s).to_i.should eq(42_i64 * 1024_i64**3)
      described_class.parse(described_class.new(43).to_s).to_i.should eq(43)
      described_class.parse(described_class.zero.to_s).to_i.should eq(0)
      described_class.parse(described_class.unlimited.to_s).to_i.should eq(-1)
    end

    it "should accept #to_human_string output" do
      described_class.parse(described_class.gib(42).to_human_string).to_i.should eq(42_i64 * 1024_i64**3)
      described_class.parse(described_class.new(43).to_human_string).to_i.should eq(43)
      described_class.parse(described_class.zero.to_human_string).to_i.should eq(0)
      described_class.parse(described_class.unlimited.to_human_string).to_i.should eq(-1)
    end

    it "should reject invalid input" do
      expect_raises(ArgumentError) { described_class.parse("wrglbrmpf") }
      expect_raises(ArgumentError) { described_class.parse("47 00 GiB") }
      expect_raises(ArgumentError) { described_class.parse("0FFF MiB") }
    end
  end

  describe "#ceil" do
    # Use 31337 bytes (prime) to ensure we don't success accidentally
    rounding = Y3Storage::DiskSize.new(31337)

    it "returns the same value if any of the operands is zero" do
      zero.ceil(rounding).should eq zero
      s.mib(4).ceil(zero).should eq s.mib(4)
      zero.ceil(zero).should eq zero
    end

    it "returns the same value if any of the operands is unlimited" do
      unlimited.ceil(rounding).should eq unlimited
      s.gib(8).ceil(unlimited).should eq s.gib(8)
      unlimited.ceil(zero).should eq unlimited
      unlimited.ceil(unlimited).should eq unlimited
    end

    it "returns the same value when rounding to 1 byte" do
      s.kib(4).ceil(one_byte).should eq s.kib(4)
    end

    it "returns the same value when it's divisible by the size" do
      value = rounding * 4
      value.ceil(rounding).should eq value
    end

    it "rounds up to the next divisible size otherwise" do
      value = rounding * 4
      value -= one_byte
      value.ceil(rounding).should eq(rounding * 4)

      value -= Y3Storage::DiskSize.new(337)
      value.ceil(rounding).should eq(rounding * 4)

      value -= rounding / 2
      value.ceil(rounding).should eq(rounding * 4)

      value = (rounding * 3) + one_byte
      value.ceil(rounding).should eq(rounding * 4)
    end
  end

  describe "#floor" do
    # Use 31337 bytes (prime) to ensure we don't success accidentally
    rounding = Y3Storage::DiskSize.new(31337)

    it "returns the same value if any of the operands is zero" do
      zero.floor(s.mib(4)).should eq zero
      s.mib(4).floor(zero).should eq s.mib(4)
      zero.floor(zero).should eq zero
    end

    it "returns the same value if any of the operands is unlimited" do
      unlimited.floor(s.gib(8)).should eq unlimited
      s.gib(8).floor(unlimited).should eq s.gib(8)
      unlimited.floor(zero).should eq unlimited
      unlimited.floor(unlimited).should eq unlimited
    end

    it "returns the same value when rounding to 1 byte" do
      s.kib(4).floor(one_byte).should eq s.kib(4)
    end

    it "returns the same value when it's divisible by the size" do
      value = rounding * 3
      value.floor(rounding).should eq value
    end

    it "rounds down to the previous divisible size otherwise" do
      value = rounding * 3
      value += one_byte
      value.floor(rounding).should eq(rounding * 3)

      value += rounding / 2
      value.floor(rounding).should eq(rounding * 3)

      value += Y3Storage::DiskSize.new(200)
      value.floor(rounding).should eq(rounding * 3)

      value = (rounding * 4) - one_byte
      value.floor(rounding).should eq(rounding * 3)
    end
  end
end
