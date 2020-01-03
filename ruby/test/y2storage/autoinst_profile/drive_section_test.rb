#!/usr/bin/env rspec
# Copyright (c) [2017-2019] SUSE LLC
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

require_relative "../spec_helper"
require_relative "#{TEST_PATH}/support/autoinst_profile_sections_examples"
require "y2storage"

describe Y2Storage::AutoinstProfile::DriveSection do
  include_examples "autoinst section"

  subject(:section) { described_class.new }

  let(:scenario) { "autoyast_drive_examples" }

  describe ".new_from_hashes" do
    let(:hash) { { "partitions" => [root] } }

    let(:root) { { "mount" => "/" } }

    it "initializes partitions" do
      expect(Y2Storage::AutoinstProfile::PartitionSection).to receive(:new_from_hashes)
        .with(root, Y2Storage::AutoinstProfile::DriveSection)
      described_class.new_from_hashes(hash)
    end

    context "when type is not specified" do
      it "initializes it to :CT_DISK" do
        expect(described_class.new_from_hashes(hash).type).to eq(:CT_DISK)
      end

      context "and device name starts by /dev/md" do
        let(:hash) { { "device" => "/dev/md0" } }

        it "initializes it to :CT_MD" do
          expect(described_class.new_from_hashes(hash).type).to eq(:CT_MD)
        end
      end

      context "and device name starts by /dev/bcache" do
        let(:hash) { { "device" => "/dev/bcache0" } }

        it "initializes it to :CT_BCACHE" do
          expect(described_class.new_from_hashes(hash).type).to eq(:CT_BCACHE)
        end
      end

      # Old format for NFS shares
      context "and device name is /dev/nfs" do
        let(:hash) { { "device" => "/dev/nfs" } }

        it "initializes it to :CT_NFS" do
          expect(described_class.new_from_hashes(hash).type).to eq(:CT_NFS)
        end
      end
    end

    # New format for NFS shares
    context "and the device is a NFS share (server:path)" do
      let(:nfs_hash) { { "device" => "192.168.56.1:/root_fs" } }

      context "and the type is specified (it must be CT_NFS)" do
        let(:hash) { nfs_hash.merge("type" => :CT_NFS) }

        it "sets the given type" do
          expect(described_class.new_from_hashes(hash).type).to eq(:CT_NFS)
        end
      end

      context "and the type is not specified" do
        let(:hash) { nfs_hash }

        # Type attribute is mandatory for NFS drives with the new format. Otherwise,
        # the type would be wrongly initialized.
        it "initializes it to :CT_DISK" do
          expect(described_class.new_from_hashes(hash).type).to eq(:CT_DISK)
        end
      end
    end

    context "when bcache options are given" do
      let(:hash) { { "partitions" => [root], "bcache_options" => bcache_options } }
      let(:bcache_options) { { "cache_mode" => "writethrough" } }

      it "initializes bcache options" do
        section = described_class.new_from_hashes(hash)
        expect(section.bcache_options.cache_mode).to eq("writethrough")
      end
    end

    context "when the raid options are given" do
      let(:hash) { { "partitions" => [root], "raid_options" => raid_options } }
      let(:raid_options) { { "raid_type" => "raid0" } }

      it "initializes raid options" do
        expect(Y2Storage::AutoinstProfile::RaidOptionsSection).to receive(:new_from_hashes)
          .with(raid_options, Y2Storage::AutoinstProfile::DriveSection)
          .and_call_original
        section = described_class.new_from_hashes(hash)
        expect(section.raid_options.raid_type).to eq("raid0")
      end

      context "and the raid_type is specified" do
        let(:raid_options) { { "raid_type" => "raid0" } }

        it "ignores the raid_name element" do
          section = described_class.new_from_hashes(hash)
          expect(section.raid_options.raid_name).to be_nil
        end
      end
    end

    context "when btrfs options are given" do
      let(:hash) { { "partitions" => [root], "btrfs_options" => btrfs_options } }
      let(:btrfs_options) { { "data_raid_level" => "single" } }

      it "initializes btrfs options" do
        section = described_class.new_from_hashes(hash)
        expect(section.btrfs_options.data_raid_level).to eq("single")
      end
    end

    context "when 'use' element is not specified" do
      let(:hash) { {} }

      it "uses nil" do
        expect(described_class.new_from_hashes(hash).use).to be_nil
      end
    end

    context "when 'use' element is specified as a list of numbers" do
      let(:hash) { { "use" => " 1,3, 5 " } }

      it "sets 'use' as an array of numbers" do
        expect(described_class.new_from_hashes(hash).use).to eq([1, 3, 5])
      end

      context "when a parent is given" do
        let(:parent) { double("parent") }
        let(:section) { described_class.new_from_hashes(hash, parent) }

        it "sets the index" do
          expect(section.parent).to eq(parent)
        end
      end
    end
  end

  describe "#to_hashes" do
    subject(:section) { described_class.new }

    it "returns a hash with all the non-blank values using strings as keys" do
      section.type = :CT_DISK
      section.use = "all"
      expect(section.to_hashes).to eq("type" => :CT_DISK, "use" => "all")
    end

    it "returns an empty hash if all the values are blank" do
      expect(section.to_hashes).to eq({})
    end

    it "exports #initialize_attr as 'initialize'" do
      section.initialize_attr = true
      hash = section.to_hashes
      expect(hash.keys).to include "initialize"
      expect(hash.keys).to_not include "initialize_attr"
      expect(hash["initialize"]).to eq true
    end

    it "does not export nil values" do
      section.disklabel = nil
      section.is_lvm_vg = nil
      section.partitions = nil
      hash = section.to_hashes
      expect(hash.keys).to_not include "disklabel"
      expect(hash.keys).to_not include "is_lvm_vg"
      expect(hash.keys).to_not include "partitions"
    end

    it "does not export empty collections (#partitions, #skip_list)" do
      section.partitions = []
      section.skip_list = []
      hash = section.to_hashes
      expect(hash.keys).to_not include "partitions"
      expect(hash.keys).to_not include "skip_list"
    end

    it "exports #partitions and #skip_list as arrays of hashes" do
      part1 = Y2Storage::AutoinstProfile::PartitionSection.new
      part1.create = true
      section.partitions << part1
      part2 = Y2Storage::AutoinstProfile::PartitionSection.new
      part2.create = false
      section.partitions << part2
      rule = instance_double(Y2Storage::AutoinstProfile::SkipRule, to_profile_rule: {})
      section.skip_list = Y2Storage::AutoinstProfile::SkipListSection.new([rule])

      hash = section.to_hashes

      expect(hash["partitions"]).to be_a(Array)
      expect(hash["partitions"].size).to eq 2
      expect(hash["partitions"]).to all(be_a(Hash))

      expect(hash["skip_list"]).to be_a(Array)
      expect(hash["skip_list"].size).to eq 1
      expect(hash["skip_list"].first).to be_a Hash
    end

    it "exports false values" do
      section.is_lvm_vg = false
      hash = section.to_hashes
      expect(hash.keys).to include "is_lvm_vg"
      expect(hash["is_lvm_vg"]).to eq false
    end

    it "does not export empty strings" do
      section.device = ""
      expect(section.to_hashes.keys).to_not include "device"
    end

    context "when use is a list of partition numbers" do
      before do
        section.use = [1, 2, 3]
      end

      it "exports 'use' as a string" do
        expect(section.to_hashes).to include("use" => "1,2,3")
      end
    end
  end

  describe "#section_name" do
    it "returns 'drives'" do
      expect(section.section_name).to eq("drives")
    end
  end

  describe "#name_for_md" do
    let(:part1) do
      instance_double(
        Y2Storage::AutoinstProfile::PartitionSection, name_for_md: "/dev/md/named", partition_nr: 1
      )
    end
    let(:part2) { instance_double(Y2Storage::AutoinstProfile::PartitionSection) }

    before do
      section.device = "/dev/md/data"
    end

    it "returns the device name" do
      expect(section.name_for_md).to eq("/dev/md/data")
    end

    context "when using the old format" do
      before do
        section.device = "/dev/md"
        section.partitions = [part1, part2]
      end

      it "returns the name for md from the same partition" do
        expect(section.name_for_md).to eq(part1.name_for_md)
      end
    end
  end

  describe "#wanted_partitions?" do
    context "when diskabel is missing" do
      it "returns false" do
        expect(section.wanted_partitions?).to eq(false)
      end
    end

    context "when disklabel is not set to 'none'" do
      before do
        section.disklabel = "gpt"
      end

      it "returns true" do
        expect(section.wanted_partitions?).to eq(true)
      end
    end

    context "when disklabel is set to 'none'" do
      before do
        section.disklabel = "none"
      end

      it "returns false" do
        expect(section.wanted_partitions?).to eq(false)
      end
    end

    context "when any partition section has the partition_nr set to '0'" do
      before do
        section.disklabel = "gpt"
        section.partitions = [
          Y2Storage::AutoinstProfile::PartitionSection.new_from_hashes("partition_nr" => 0)
        ]
      end

      it "returns false" do
        expect(section.wanted_partitions?).to eq(false)
      end
    end
  end

  describe "#unwanted_partitions?" do
    context "when diskabel is missing" do
      it "returns false" do
        expect(section.unwanted_partitions?).to eq(false)
      end
    end

    context "when disklabel is not set to 'none'" do
      before do
        section.disklabel = "gpt"
      end

      it "returns false" do
        expect(section.unwanted_partitions?).to eq(false)
      end
    end

    context "when disklabel is set to 'none'" do
      before do
        section.disklabel = "none"
      end

      it "returns true" do
        expect(section.unwanted_partitions?).to eq(true)
      end
    end

    context "when any partition section has the partition_nr set to '0'" do
      before do
        section.disklabel = "gpt"
        section.partitions = [
          Y2Storage::AutoinstProfile::PartitionSection.new_from_hashes("partition_nr" => 0)
        ]
      end

      it "returns true" do
        expect(section.unwanted_partitions?).to eq(true)
      end
    end
  end

  describe "#master_partition" do
    let(:part0_spec) do
      Y2Storage::AutoinstProfile::PartitionSection.new_from_hashes(
        "mount" => "/", "partition_nr" => 0
      )
    end

    let(:home_spec) { Y2Storage::AutoinstProfile::PartitionSection.new }

    before do
      section.partitions = [home_spec, part0_spec]
    end

    context "when diskabel is set to 'none'" do
      before do
        section.disklabel = "none"
      end

      it "returns the partition which partition_nr is set to '0'" do
        expect(section.master_partition).to eq(part0_spec)
      end

      context "but no partition section has the partition_nr set to '0'" do
        before do
          section.partitions = [home_spec]
        end

        it "returns the first one" do
          expect(section.master_partition).to eq(home_spec)
        end
      end

      context "but no partition section is defined" do
        before do
          section.partitions = []
        end

        it "returns nil" do
          expect(section.master_partition).to be_nil
        end
      end
    end

    context "when a partition section has the partition_nr set to '0'" do
      it "returns that partition section" do
        expect(section.master_partition).to eq(part0_spec)
      end

      context "and disklabel is set to a value different than '0'" do
        before do
          section.disklabel = "gpt"
        end

        it "still returns the partition section which has the partition_nr set to '0'" do
          expect(section.master_partition).to eq(part0_spec)
        end
      end
    end
  end
end
