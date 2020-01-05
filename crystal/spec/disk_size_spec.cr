require "./spec_helper"

Spectator.describe Y3Storage::DiskSize do
  let(:zero) { Y3Storage::DiskSize.zero }
  let(:unlimited) { Y3Storage::DiskSize.unlimited }
  let(:one_byte) { Y3Storage::DiskSize.new(1) }

  describe ".new" do
    context "when no param is passed" do
      it "creates a disk size of 0 bytes" do
        expect(described_class.new.size).to eq(0)
      end
    end

    context "when a number is passed" do
      context "and is a natural number" do
        it "creates a disk size with this number of bytes" do
          expect(described_class.new(5).size).to eq(5)
        end
      end

      context "and is a floating point number" do
        it "creates a disk size with a rounded number of bytes" do
          expect(described_class.new(5.6).size).to eq(6)
          expect(described_class.new(5.4).size).to eq(5)
        end
      end
    end

    context "when a string is passed" do
      it "creates a disk size with the number of bytes represented by the string" do
        expect(described_class.new("5").size).to eq(5)
        expect(described_class.new("15 KB").size).to eq(15 * 1000)
        expect(described_class.new("15 MiB").size).to eq(15 * 1024**2)
        expect(described_class.new("23 TiB").size).to eq(23_u64 * 1024_u64**4)
        expect(described_class.new("23.2 KiB").size).to eq((23.2 * 1024).to_i)
      end
    end
  end

  describe ".b" do
    it "creates a disk size from a number of bytes" do
      expect(described_class.b(5).size).to eq(5)
    end
  end

  describe ".kib" do
    it "creates a disk size from a number of KiB" do
      expect(described_class.kib(5).size).to eq(5 * 1024)
    end
  end

  describe ".mib" do
    it "creates a disk size from a number of MiB" do
      expect(described_class.mib(5).size).to eq(5 * 1024**2)
    end
  end

  describe ".gib" do
    it "creates a disk size from a number of GiB" do
      expect(described_class.gib(5).size).to eq(5_i64 * 1024_i64**3)
    end
  end

  describe ".tib" do
    it "creates a disk size from a number of TiB" do
      expect(described_class.tib(5).size).to eq(5_i64 * 1024_i64**4)
    end
  end

  describe ".pib" do
    it "creates a disk size from a number of PiB" do
      expect(described_class.pib(5).size).to eq(5_i64 * 1024_i64**5)
    end
  end

  describe ".eib" do
    it "creates a disk size from a number of EiB" do
      expect(described_class.eib(5).size).to eq(5_i64 * 1024_i64**6)
    end
  end

  # describe ".zib" do
  #   it "creates a disk size from a number of ZiB" do
  #     expect(described_class.zib(5).size).to eq(5 * 1024**7)
  #   end
  # end

  # describe ".yib" do
  #   it "creates a disk size from a number of YiB" do
  #     expect(described_class.yib(5).size).to eq(5 * 1024**8)
  #   end
  # end

  describe ".kb" do
    it "creates a disk size from a number of KB" do
      expect(described_class.kb(5).size).to eq(5 * 1000)
    end
  end

  describe ".mb" do
    it "creates a disk size from a number of MB" do
      expect(described_class.mb(5).size).to eq(5 * 1000**2)
    end
  end

  describe ".gb" do
    it "creates a disk size from a number of GB" do
      expect(described_class.gb(5).size).to eq(5_i64 * 1000_i64**3)
    end
  end

  describe ".tb" do
    it "creates a disk size from a number of TB" do
      expect(described_class.tb(5).size).to eq(5_i64 * 1000_i64**4)
    end
  end

  describe ".pb" do
    it "creates a disk size from a number of PB" do
      expect(described_class.pb(5).size).to eq(5_i64 * 1000_i64**5)
    end
  end

  describe ".eb" do
    it "creates a disk size from a number of EB" do
      expect(described_class.eb(5).size).to eq(5_i64 * 1000_i64**6)
    end
  end

  # describe ".zb" do
  #   it "creates a disk size from a number of ZB" do
  #     expect(described_class.zb(5).size).to eq(5 * 1000**7)
  #   end
  # end

  # describe ".yb" do
  #   it "creates a disk size from a number of YB" do
  #     expect(described_class.yb(5).size).to eq(5 * 1000**8)
  #   end
  # end

  describe ".to_human_string" do
    context "when has a specific size" do
      it("returns human-readable string represented in the biggest possible unit") do
        expect(described_class.b(5 * 1024**0).to_human_string).to eq("5.00 B")
        expect(described_class.b(5 * 1024**1).to_human_string).to eq("5.00 KiB")
        expect(described_class.b(5_i64 * 1024_i64**3).to_human_string).to eq("5.00 GiB")
        expect(described_class.b(5_i64 * 1024_i64**4).to_human_string).to eq("5.00 TiB")
        # expect(described_class.b(5 * 1024**7).to_human_string).to eq("5.00 ZiB")
      end
    end

    context "when has unlimited size" do
      it "returns 'unlimited'" do
        expect(described_class.unlimited.to_human_string).to eq("unlimited")
      end
    end
  end

  describe ".human_floor" do
    context "when it has a specific size" do
      it("returns human-readable string not exceeding the actual size") do
        expect(described_class.b(4095 * 1024**0).human_floor).to eq("3.99 KiB")
        expect(described_class.b(4095_i64 * 1024_i64**3).human_floor).to eq("3.99 TiB")
      end
    end

    context "when it has unlimited size" do
      it "returns 'unlimited'" do
        expect(described_class.unlimited.human_floor).to eq("unlimited")
      end
    end
  end

  describe ".human_ceil" do
    context "when it has a specific size" do
      it("returns human-readable string not exceeding the actual size") do
        expect(described_class.b(4097 * 1024**0).human_ceil).to eq("4.01 KiB")
        expect(described_class.b(4097_i64 * 1024_i64**3).human_ceil).to eq("4.01 TiB")
      end
    end

    context "when it has unlimited size" do
      it "returns 'unlimited'" do
        expect(described_class.unlimited.human_ceil).to eq("unlimited")
      end
    end
  end

  describe "#+" do
    it "should accept addition of another DiskSize" do
      disk_size = Y3Storage::DiskSize.gib(10) + Y3Storage::DiskSize.gib(20)
      expect(disk_size.to_i).to be == 30_i64 * 1024_i64**3
    end
    it "should accept addition of an int" do
      disk_size = Y3Storage::DiskSize.mib(20) + 512
      expect(disk_size.to_i).to be == 20 * 1024**2 + 512
    end
    it "should accept addition of a string with a valid disk size spec" do
      disk_size = Y3Storage::DiskSize.mib(20) + "512 KiB"
      expect(disk_size.to_i).to be == 20 * 1024**2 + 512 * 1024
    end
    it "should refuse addition of a random string" do
      expect { Y3Storage::DiskSize.mib(20) + "Foo Bar" }
        .to raise_error ArgumentError
    end
    it "should refuse addition of another type" do
      expect { Y3Storage::DiskSize.mib(20) + true }
        .to raise_error ArgumentError
    end
  end

  describe "#-" do
    it "should accept subtraction of another DiskSize" do
      disk_size = Y3Storage::DiskSize.gib(20) - Y3Storage::DiskSize.gib(5)
      expect(disk_size.to_i).to be == 15_i64 * 1024_i64**3
    end
    it "should accept subtraction of an int" do
      disk_size = Y3Storage::DiskSize.kib(3) - 1024
      expect(disk_size.to_i).to be == 2048
    end
    it "should accept subtraction of a string with a valid disk size spec" do
      disk_size = Y3Storage::DiskSize.mib(20) - "512 KiB"
      expect(disk_size.to_i).to be == 20 * 1024**2 - 512 * 1024
    end
    it "should refuse subtraction of a random string" do
      expect { Y3Storage::DiskSize.mib(20) - "Foo Bar" }
        .to raise_error ArgumentError
    end
    it "should refuse subtraction of another type" do
      expect { Y3Storage::DiskSize.mib(20) - true }
        .to raise_error ArgumentError
    end
  end

  describe "#%" do
    it "should accept another DiskSize" do
      disk_size = Y3Storage::DiskSize.kib(2) % Y3Storage::DiskSize.kb(1)
      expect(disk_size.to_i).to be == 48
    end
    it "should accept an int" do
      disk_size = Y3Storage::DiskSize.kib(4) % 1000
      expect(disk_size.to_i).to be == 96
    end
    it "should accept a string with a valid disk size spec" do
      disk_size = Y3Storage::DiskSize.mib(20) % "100 KB"
      expect(disk_size.to_i).to be == 20 * 1024**2 % (100 * 1000)
    end
    it "should refuse a random string" do
      expect { Y3Storage::DiskSize.mib(20) % "Foo Bar" }
        .to raise_error ArgumentError
    end
    it "should refuse another type" do
      expect { Y3Storage::DiskSize.mib(20) % true }
        .to raise_error ArgumentError
    end
  end

  describe "#*" do
    it "should accept multiplication with an int" do
      disk_size = Y3Storage::DiskSize.mib(12) * 3
      expect(disk_size.to_i).to be == 12 * 1024**2 * 3
    end
    it "should accept multiplication with a float" do
      disk_size = Y3Storage::DiskSize.b(10) * 4.5
      expect(disk_size.to_i).to be == 45
    end
    it "should refuse multiplication with a string" do
      expect { Y3Storage::DiskSize.mib(12) * "100" }
        .to raise_error ArgumentError
    end
    it "should refuse multiplication with another DiskSize" do
      expect { Y3Storage::DiskSize.mib(12) * Y3Storage::DiskSize.mib(3) }
        .to raise_error ArgumentError
    end
  end

  describe "#/" do
    it "should accept division by an int" do
      disk_size = Y3Storage::DiskSize.mib(12) / 3
      expect(disk_size.to_i).to be == 12 / 3 * 1024**2
    end
    it "should accept division by a float" do
      disk_size = Y3Storage::DiskSize.b(10) / 2.5
      expect(disk_size.to_i).to be == 4
    end
    it "should refuse division by a string" do
      expect { Y3Storage::DiskSize.mib(12) / "100" }
        .to raise_error ArgumentError
    end
    it "should refuse division by another type" do
      expect { Y3Storage::DiskSize.mib(20) / true }
        .to raise_error ArgumentError
    end
    # DiskSize / DiskSize should be possible, returning an int,
    # but we haven't needed it so far.
  end

  describe "arithmetic operations with unlimited and DiskSize" do
    let(:unlimited) { Y3Storage::DiskSize.unlimited }
    let(:disk_size) { Y3Storage::DiskSize.gib(42) }
    it "should return unlimited" do
      expect(unlimited + disk_size).to be == unlimited
      expect(disk_size + unlimited).to be == unlimited
      expect(unlimited - disk_size).to be == unlimited
      expect(disk_size - unlimited).to be == unlimited
      # DiskSize * DiskSize and DiskSize / DiskSize are undefined
    end
  end

  describe "arithmetic operations with unlimited and a number" do
    let(:unlimited) { Y3Storage::DiskSize.unlimited }
    let(:number) { 7 }
    it "should return unlimited" do
      expect(unlimited + number).to be == unlimited
      expect(unlimited - number).to be == unlimited
      expect(unlimited * number).to be == unlimited
      expect(unlimited / number).to be == unlimited
    end
  end

  describe "#power_of?" do
    context "when the number of bytes is power of the given value" do
      it "returns true" do
        expect(8.mib.power_of?(2)).to eq true
        expect(100.kb.power_of?(10)).to eq true
      end
    end

    context "when the number of bytes is not power of the given value" do
      it "returns false" do
        expect(8.mib.power_of?(10)).to eq false
        expect(100.mib.power_of?(2)).to eq false
      end
    end

    context "when the size is zero" do
      it "returns false" do
        expect(described_class.zero.power_of?(0)).to eq false
        expect(described_class.zero.power_of?(1)).to eq false
        expect(described_class.zero.power_of?(2)).to eq false
        expect(described_class.zero.power_of?(5)).to eq false
      end
    end

    context "when the size is unlimited" do
      let(:disk_size) { unlimited }

      it "returns false" do
        expect(described_class.unlimited.power_of?(0)).to eq false
        expect(described_class.unlimited.power_of?(1)).to eq false
        expect(described_class.unlimited.power_of?(2)).to eq false
        expect(described_class.unlimited.power_of?(5)).to eq false
      end
    end
  end

  describe "comparison" do
    let(:disk_size1) { Y3Storage::DiskSize.gib(24) }
    let(:disk_size2) { Y3Storage::DiskSize.gib(32) }
    let(:disk_size3) { Y3Storage::DiskSize.gib(32) }
    it "operator < should compare correctly" do
      expect(disk_size1 < disk_size2).to be == true
      expect(disk_size2 < disk_size3).to be == false
    end
    it "operator > should compare correctly" do
      expect(disk_size1 > disk_size2).to be == false
      expect(disk_size2 > disk_size3).to be == false
    end
    it "operator == should compare correctly" do
      expect(disk_size2 == disk_size3).to be == true
    end
    it "operator != should compare correctly" do
      expect(disk_size1 != disk_size2).to be == true
    end
    it "operator <= should compare correctly" do
      expect(disk_size2 <= disk_size3).to be == true
    end
    it "operator >= should compare correctly" do
      expect(disk_size2 >= disk_size3).to be == true
    end
    # Comparing with an integer (#to_i) seems to make sense,
    # but we haven't needed it so far.
  end

  describe "comparison with unlimited" do
    let(:unlimited) { Y3Storage::DiskSize.unlimited }
    let(:disk_size) { Y3Storage::DiskSize.gib(42) }
    it "should compare any disk size correctly with unlimited" do
      expect(disk_size).to be < unlimited
      expect(disk_size).to_not be > unlimited
      expect(disk_size).to_not eq unlimited
    end
    it "should compare unlimited correctly with any disk size" do
      expect(unlimited).to be > disk_size
      expect(unlimited).to_not be < disk_size
      expect(unlimited).to_not eq disk_size
    end
    it "should compare unlimited correctly with unlimited" do
      expect(unlimited).to_not be > unlimited
      expect(unlimited).to_not be < unlimited
      expect(unlimited).to eq unlimited
    end
  end

  describe ".parse" do
    it "should work with just a number" do
      expect(described_class.parse("0").to_i).to eq(0)
      expect(described_class.parse("7").to_i).to eq(7)
      expect(described_class.parse("7.00").to_i).to eq(7)
    end

    it "should also accept signed numbers" do
      expect(described_class.parse("-12").to_i).to eq(-12)
      expect(described_class.parse("+12").to_i).to eq(+12)
    end

    it "should work with integer and unit" do
      expect(described_class.parse("42 GiB").to_i).to eq(42_i64 * 1024_i64**3)
      expect(described_class.parse("-42 GiB").to_i).to eq(-42_i64 * 1024_i64**3)
    end

    it "should work with float and unit" do
      expect(described_class.parse("43.00 GiB").to_i).to eq(43_i64 * 1024_i64**3)
      expect(described_class.parse("-43.00 GiB").to_i).to eq(-43_i64 * 1024_i64**3)
    end

    it "should work with non-integral numbers and unit" do
      expect(described_class.parse("43.456 GB").to_i).to eq(43.456 * 1000**3)
      expect(described_class.parse("-43.456 GB").to_i).to eq(-43.456 * 1000**3)
    end

    it "should work with integer and unit without space between them" do
      expect(described_class.parse("10MiB").to_i).to eq(10 * 1024**2)
    end

    it "should work with float and unit without space between them" do
      expect(described_class.parse("10.00MiB").to_i).to eq(10 * 1024**2)
    end

    it "should tolerate more embedded whitespace" do
      expect(described_class.parse("44   MiB").to_i).to eq(44 * 1024**2)
    end

    it "should tolerate more surrounding whitespace" do
      expect(described_class.parse("   45   TiB  ").to_i).to eq(45_i64 * 1024_i64**4)
      expect(described_class.parse("  46   ").to_i).to eq(46)
    end

    it "should accept \"unlimited\"" do
      expect(described_class.parse("unlimited").to_i).to eq(-1)
    end

    it "should accept \"unlimited\" with surrounding whitespace" do
      expect(described_class.parse("  unlimited ").to_i).to eq(-1)
    end

    it "should accept International System units" do
      expect(described_class.parse("10 KB").to_i).to eq(10 * 1000)
      expect(described_class.parse("10 MB").to_i).to eq(10 * 1000**2)
    end

    it "should accept deprecated units" do
      expect(described_class.parse("10 K").to_i).to eq(10_i64 * 1000_i64)
      expect(described_class.parse("10 M").to_i).to eq(10_i64 * 1000_i64**2)
      expect(described_class.parse("10 G").to_i).to eq(10_i64 * 1000_i64**3)
    end

    it "should not be case sensitive" do
      expect(described_class.parse("10k").to_i).to eq(10 * 1000)
      expect(described_class.parse("10Kb").to_i).to eq(10 * 1000)
    end

    context "when using the legacy_unit flag" do
      let(:legacy) { true }

      it "considers international system units to be power of two" do
        expect(described_class.parse("10 MB", legacy_units: legacy).size).to eq(10 * 1024**2)
      end

      it "considers deprecated units to be power of two" do
        expect(described_class.parse("10 M", legacy_units: legacy).to_i).to eq(10 * 1024**2)
      end

      it "reads units that are power of two in the usual way" do
        expect(described_class.parse("10 MiB", legacy_units: legacy).size).to eq(10 * 1024**2)
      end
    end

    it "should accept #to_s output" do
      # expect(described_class.parse(described_class.gib(42).to_s).to_i).to eq(42_i64 * 1024_i64**3)
      expect(described_class.parse(described_class.new(43).to_s).to_i).to eq(43)
      expect(described_class.parse(described_class.zero.to_s).to_i).to eq(0)
      expect(described_class.parse(described_class.unlimited.to_s).to_i).to eq(-1)
    end

    it "should accept #to_human_string output" do
      expect(described_class.parse(described_class.gib(42).to_human_string).to_i).to eq(42_i64 * 1024_i64**3)
      expect(described_class.parse(described_class.new(43).to_human_string).to_i).to eq(43)
      expect(described_class.parse(described_class.zero.to_human_string).to_i).to eq(0)
      expect(described_class.parse(described_class.unlimited.to_human_string).to_i).to eq(-1)
    end

    it "should reject invalid input" do
      expect { described_class.parse("wrglbrmpf") }.to raise_error ArgumentError
      expect { described_class.parse("47 00 GiB") }.to raise_error ArgumentError
      expect { described_class.parse("0FFF MiB") }.to raise_error ArgumentError
    end
  end

  describe "#ceil" do
    # Use 31337 bytes (prime) to ensure we don't success accidentally
    let(:rounding) { Y3Storage::DiskSize.new(31337) }

    it "returns the same value if any of the operands is zero" do
      expect(zero.ceil(rounding)).to eq zero
      expect(4.mib.ceil(zero)).to eq 4.mib
      expect(zero.ceil(zero)).to eq zero
    end

    it "returns the same value if any of the operands is unlimited" do
      expect(unlimited.ceil(rounding)).to eq unlimited
      expect(8.gib.ceil(unlimited)).to eq 8.gib
      expect(unlimited.ceil(zero)).to eq unlimited
      expect(unlimited.ceil(unlimited)).to eq unlimited
    end

    it "returns the same value when rounding to 1 byte" do
      expect(4.kib.ceil(one_byte)).to eq 4.kib
    end

    it "returns the same value when it's divisible by the size" do
      value = rounding * 4
      expect(value.ceil(rounding)).to eq value
    end

    it "rounds up to the next divisible size otherwise" do
      value = rounding * 4
      value -= one_byte
      expect(value.ceil(rounding)).to eq(rounding * 4)

      value -= Y3Storage::DiskSize.new(337)
      expect(value.ceil(rounding)).to eq(rounding * 4)

      value -= rounding / 2
      expect(value.ceil(rounding)).to eq(rounding * 4)

      value = (rounding * 3) + one_byte
      expect(value.ceil(rounding)).to eq(rounding * 4)
    end
  end

  describe "#floor" do
    # Use 31337 bytes (prime) to ensure we don't success accidentally
    let(:rounding) { Y3Storage::DiskSize.new(31337) }

    it "returns the same value if any of the operands is zero" do
      expect(zero.floor(4.mib)).to eq zero
      expect(4.mib.floor(zero)).to eq 4.mib
      expect(zero.floor(zero)).to eq zero
    end

    it "returns the same value if any of the operands is unlimited" do
      expect(unlimited.floor(8.gib)).to eq unlimited
      expect(8.gib.floor(unlimited)).to eq 8.gib
      expect(unlimited.floor(zero)).to eq unlimited
      expect(unlimited.floor(unlimited)).to eq unlimited
    end

    it "returns the same value when rounding to 1 byte" do
      expect(4.kib.floor(one_byte)).to eq 4.kib
    end

    it "returns the same value when it's divisible by the size" do
      value = rounding * 3
      expect(value.floor(rounding)).to eq value
    end

    it "rounds down to the previous divisible size otherwise" do
      value = rounding * 3
      value += one_byte
      expect(value.floor(rounding)).to eq(rounding * 3)

      value += rounding / 2
      expect(value.floor(rounding)).to eq(rounding * 3)

      value += Y3Storage::DiskSize.new(200)
      expect(value.floor(rounding)).to eq(rounding * 3)

      value = (rounding * 4) - one_byte
      expect(value.floor(rounding)).to eq(rounding * 3)
    end
  end
end
