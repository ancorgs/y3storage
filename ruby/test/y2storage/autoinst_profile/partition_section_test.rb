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

describe Y2Storage::AutoinstProfile::PartitionSection do
  using Y2Storage::Refinements::SizeCasts

  subject(:section) { described_class.new }

  include_examples "autoinst section"

  describe "#type_for_filesystem" do
    subject(:section) { described_class.new }

    it "returns nil if #filesystem is not set" do
      section.filesystem = nil
      expect(subject.type_for_filesystem).to be_nil
    end

    it "returns a Filesystems::Type corresponding to the symbol at #filesystem" do
      section.filesystem = :swap
      expect(subject.type_for_filesystem).to eq Y2Storage::Filesystems::Type::SWAP
      section.filesystem = :btrfs
      expect(subject.type_for_filesystem).to eq Y2Storage::Filesystems::Type::BTRFS
    end

    it "returns nil for unknown values of #filesystem" do
      section.filesystem = :strange
      expect(subject.type_for_filesystem).to be_nil
    end
  end

  describe "#type_for_mountby" do
    subject(:section) { described_class.new }

    it "returns nil if #mountby is not set" do
      section.mountby = nil
      expect(subject.type_for_mountby).to be_nil
    end

    it "returns a Filesystems::Type corresponding to the symbol at #filesystem" do
      section.mountby = :uuid
      expect(subject.type_for_mountby).to eq Y2Storage::Filesystems::MountByType::UUID
      section.mountby = :device
      expect(subject.type_for_mountby).to eq Y2Storage::Filesystems::MountByType::DEVICE
    end

    it "returns nil for unknown values of #filesystem" do
      section.filesystem = :strange
      expect(subject.type_for_filesystem).to be_nil
    end
  end

  describe "#id_for_partition" do
    subject(:section) { described_class.new }

    before { section.partition_id = partition_id }

    context "if #partition_id is set" do
      context "to a legacy integer value" do
        let(:partition_id) { 263 }

        it "returns the corresponding PartitionId object" do
          expect(section.id_for_partition).to eq Y2Storage::PartitionId::BIOS_BOOT
        end
      end

      context "to a standard integer value" do
        let(:partition_id) { 7 }

        it "returns the corresponding PartitionId object" do
          expect(section.id_for_partition).to eq Y2Storage::PartitionId::NTFS
        end
      end
    end

    context "if #partition_id is not set" do
      let(:partition_id) { nil }

      it "returns PartitionId:SWAP if #filesystem is :swap" do
        section.filesystem = :swap
        expect(section.id_for_partition).to eq Y2Storage::PartitionId::SWAP
      end

      it "returns PartitionId::LINUX for any other #filesystem value" do
        section.filesystem = :btrfs
        expect(section.id_for_partition).to eq Y2Storage::PartitionId::LINUX
        section.filesystem = :ntfs
        expect(section.id_for_partition).to eq Y2Storage::PartitionId::LINUX
        section.filesystem = nil
        expect(section.id_for_partition).to eq Y2Storage::PartitionId::LINUX
      end
    end
  end

  describe "#name_for_md" do
    let(:partition) { Y2Storage::AutoinstProfile::PartitionSection.new }

    before do
      section.partition_nr = 3
    end

    # Let's ensure DriveSection#raid_name (which has the same name but
    # completely different meaning) has no influence in the result
    context "if #raid_name (attribute directly in the partition) has value" do
      before { partition.raid_name = "/dev/md25" }

      context "if there is no <raid_options> section" do
        it "returns a name based on partition_nr" do
          expect(section.name_for_md).to eq "/dev/md/3"
        end
      end

      context "if there is a <raid_options> section" do
        let(:raid_options) { Y2Storage::AutoinstProfile::RaidOptionsSection.new }
        before { section.raid_options = raid_options }

        context "if <raid_options> contains an nil raid_name attribute" do
          it "returns a name based on partition_nr" do
            expect(section.name_for_md).to eq "/dev/md/3"
          end
        end

        context "if <raid_options> contains an empty raid_name attribute" do
          before { raid_options.raid_name = "" }

          it "returns a name based on partition_nr" do
            expect(section.name_for_md).to eq "/dev/md/3"
          end
        end

        context "if <raid_options> contains an non-empty raid_name attribute" do
          before { raid_options.raid_name = "/dev/md6" }

          it "returns the name specified in <raid_options>" do
            expect(section.name_for_md).to eq "/dev/md6"
          end
        end
      end
    end

    context "if #raid_name (attribute directly in the partition) is nil" do
      context "if there is no <raid_options> section" do
        it "returns a name based on partition_nr" do
          expect(section.name_for_md).to eq "/dev/md/3"
        end
      end

      # Same logic than above, there is no need to return all the possible
      # sub-contexts
      context "if there is a <raid_options> section with a raid name" do
        let(:raid_options) { Y2Storage::AutoinstProfile::RaidOptionsSection.new }
        before do
          section.raid_options = raid_options
          raid_options.raid_name = "/dev/md7"
        end

        it "returns a name based in <raid_options>" do
          expect(section.name_for_md).to eq "/dev/md7"
        end
      end
    end
  end

  describe "#section_name" do
    it "returns 'partitions'" do
      expect(section.section_name).to eq("partitions")
    end
  end
end
