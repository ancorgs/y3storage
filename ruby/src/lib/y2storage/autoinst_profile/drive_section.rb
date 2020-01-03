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

require "y2storage/autoinst_profile/section_with_attributes"
require "y2storage/autoinst_profile/skip_list_section"
require "y2storage/autoinst_profile/partition_section"
require "y2storage/autoinst_profile/raid_options_section"
require "y2storage/autoinst_profile/bcache_options_section"
require "y2storage/autoinst_profile/btrfs_options_section"

# FIXME: class too long, refactoring needed.
#
# rubocop:disable ClassLength
module Y2Storage
  module AutoinstProfile
    # Thin object oriented layer on top of a <drive> section of the
    # AutoYaST profile.
    #
    # More information can be found in the 'Partitioning' section of the AutoYaST documentation:
    # https://www.suse.com/documentation/sles-12/singlehtml/book_autoyast/book_autoyast.html#CreateProfile.Partitioning
    # Check that document for details about the semantic of every attribute.
    class DriveSection < SectionWithAttributes
      def self.attributes
        [
          { name: :device },
          { name: :disklabel },
          { name: :enable_snapshots },
          { name: :imsmdriver },
          { name: :initialize_attr, xml_name: :initialize },
          { name: :keep_unknown_lv },
          { name: :lvm2 },
          { name: :is_lvm_vg },
          { name: :partitions },
          { name: :pesize },
          { name: :type },
          { name: :use },
          { name: :skip_list },
          { name: :raid_options },
          { name: :bcache_options },
          { name: :btrfs_options }
        ]
      end

      define_attr_accessors

      # @!attribute device
      #   @return [String] device name

      # @!attribute disklabel
      #   @return [String] partition table type

      # @!attribute enable_snapshots
      #   @return [Boolean] undocumented attribute

      # @!attribute imsmdriver
      #   @return [Symbol] undocumented attribute

      # @!attribute initialize_attr
      #   @return [Boolean] value of the 'initialize' attribute in the profile
      #     (reserved name in Ruby). Whether the partition table must be wiped
      #     out at the beginning of the AutoYaST process.

      # @!attribute keep_unknown_lv
      #   @return [Boolean] whether the existing logical volumes should be
      #   kept. Only makes sense if #type is :CT_LVM and there is a volume group
      #   to reuse.

      # @!attribute lvm2
      #   @return [Boolean] undocumented attribute

      # @!attribute is_lvm_vg
      #   @return [Boolean] undocumented attribute

      # @!attribute partitions
      #   @return [Array<PartitionSection>] a list of <partition> entries

      # @!attribute pesize
      #   @return [String] size of the LVM PE

      # @!attribute type
      #   @return [Symbol] :CT_DISK or :CT_LVM

      # @!attribute use
      #   @return [String,Array<Integer>] strategy AutoYaST will use to partition the disk

      # @!attribute skip_list
      #   @return [Array<SkipListSection] collection of <skip_list> entries

      # @!attribute raid_options
      #   @return [RaidOptionsSection] RAID options
      #   @see RaidOptionsSection

      # @!attribute bcache_options
      #   @return [BcacheOptionsSection] bcache options
      #   @see BcacheOptionsSection

      # @!attribute btrfs_options
      #   @return [BtrfsOptionsSection] Btrfs options
      #   @see BtrfsOptionsSection

      # Constructor
      #
      # @param parent [#parent,#section_name] parent section
      def initialize(parent = nil)
        @parent = parent
        @partitions = []
        @skip_list = SkipListSection.new([])
      end

      # Method used by {.new_from_hashes} to populate the attributes.
      #
      # It only enforces default values for #type (:CT_DISK) and #use ("all")
      # since the {AutoinstProposal} algorithm relies on them.
      #
      # @param hash [Hash] see {.new_from_hashes}
      def init_from_hashes(hash)
        super
        @type ||= default_type_for(hash)
        @use = use_value_from_string(hash["use"]) if hash["use"]
        @partitions = partitions_from_hash(hash)
        @skip_list = SkipListSection.new_from_hashes(hash.fetch("skip_list", []), self)
        if hash["raid_options"]
          @raid_options = RaidOptionsSection.new_from_hashes(hash["raid_options"], self)
          @raid_options.raid_name = nil # This element is not supported here
        end
        if hash["bcache_options"]
          @bcache_options = BcacheOptionsSection.new_from_hashes(hash["bcache_options"], self)
        end
        if hash["btrfs_options"]
          @btrfs_options = BtrfsOptionsSection.new_from_hashes(hash["btrfs_options"], self)
        end

        nil
      end

      # Default drive type depending on the device name
      #
      # For NFS, the default type can only be inferred when using the old format. With the new
      # format, type attribute is mandatory.
      #
      # @param hash [Hash]
      # @return [Symbol]
      def default_type_for(hash)
        device_name = hash["device"].to_s

        if md_name?(device_name)
          :CT_MD
        elsif bcache_name?(device_name)
          :CT_BCACHE
        elsif nfs_name?(device_name)
          :CT_NFS
        else
          :CT_DISK
        end
      end

      # Device name to be used for the real MD device
      #
      # @see PartitionSection#name_for_md for details
      #
      # @return [String] MD RAID device name
      def name_for_md
        return partitions.first.name_for_md if device == "/dev/md"

        device
      end

      # Content of the section in the format used by the AutoYaST modules
      #
      # @return [Hash] each element of the hash corresponds to one of the
      #     attributes defined in the section. Blank attributes are not
      #     included.
      def to_hashes
        hash = super
        hash["use"] = use.join(",") if use.is_a?(Array)
        hash
      end

      # Return section name
      #
      # @return [String] "drives"
      def section_name
        "drives"
      end

      # @return [String] disklabel value which indicates that no partition table is wanted.
      NO_PARTITION_TABLE = "none".freeze

      # Determine whether the partition table is explicitly not wanted
      #
      # @note When the disklabel is set to 'none', a partition table should not be created.
      #   For backward compatibility reasons, setting partition_nr to 0 has the same effect.
      #   When no disklabel is set, this method returns false.
      #
      # @return [Boolean] Returns true when a partition table is wanted; false otherwise.
      def unwanted_partitions?
        disklabel == NO_PARTITION_TABLE || partitions.any? { |i| i.partition_nr == 0 }
      end

      # Determines whether a partition table is explicitly wanted
      #
      # @note When the disklabel is set to some value which does not disable partitions,
      #   a partition table is expected. When no disklabel is set, this method returns
      #   false.
      #
      # @see unwanted_partitions?
      # @return [Boolean] Returns true when a partition table is wanted; false otherwise.
      def wanted_partitions?
        !(disklabel.nil? || unwanted_partitions?)
      end

      # Returns the partition which contains the configuration for the whole disk
      #
      # @return [PartitionSection,nil] Partition section for the whole disk; it returns
      #   nil if the device will use a partition table.
      #
      # @see #partition_table?
      def master_partition
        return unless unwanted_partitions?

        partitions.find { |i| i.partition_nr == 0 } || partitions.first
      end

      protected

      # Whether the given name is a Md name
      #
      # @param device_name [String]
      # @return [Boolean]
      def md_name?(device_name)
        device_name.start_with?("/dev/md")
      end

      # Whether the given name is a Bcache name
      #
      # @param device_name [String]
      # @return [Boolean]
      def bcache_name?(device_name)
        device_name.start_with?("/dev/bcache")
      end

      # Whether the given name is a NFS name
      #
      # Note that this method only recognizes a NFS name when the old format is used,
      # that is, device attribute contains "/dev/nfs". With the new format, device
      # contains the NFS share name (server:path), but in this case the type attribute
      # is mandatory to identify the drive type.
      #
      # @param device_name [String]
      # @return [Boolean]
      def nfs_name?(device_name)
        device_name == "/dev/nfs"
      end

      def partitions_from_hash(hash)
        return [] unless hash["partitions"]

        hash["partitions"].map { |part| PartitionSection.new_from_hashes(part, self) }
      end

      # Return the partition sections for the given disk
      #
      # @note If there is no partition table, an array containing a single section
      #   (which represents the whole disk) will be returned.
      #
      # @return [Array<AutoinstProfile::PartitionSection>] List of partition sections
      def partitions_from_disk(disk)
        if disk.partition_table
          collection = disk.partitions.reject { |p| skip_partition?(p) }
          partitions_from_collection(collection.sort_by(&:number))
        else
          [PartitionSection.new_from_storage(disk)]
        end
      end

      def partitions_from_collection(collection)
        collection.each_with_object([]) do |storage_partition, result|
          partition = PartitionSection.new_from_storage(storage_partition)
          next unless partition

          result << partition
        end
      end

      # Return value for the "use" element
      #
      # If the given string is a comma separated list of numbers, it will
      # return an array containing those numbers. Otherwise, the original
      # value will be returned.
      #
      # @return [String,Array<Integer>]
      def use_value_from_string(use)
        return use unless use =~ /(\d+,?)+/

        use.split(",").select { |n| n =~ /\d+/ }.map(&:to_i)
      end

      # Determine whether snapshots are enabled
      #
      # Currently AutoYaST does not support enabling/disabling snapshots
      # for a partition but for the whole disk/volume group.
      #
      # @param filesystems [Array<Y2Storage::Filesystem>] Filesystems to evaluate
      # @return [Boolean] true if snapshots are enabled
      def enabled_snapshots?(filesystems)
        filesystems.any? { |f| f.respond_to?(:snapshots?) && f.snapshots? }
      end

      # Determine whether the disk is used or not
      #
      # @param disk [Array<Y2Storage::Disk,Y2Storage::Dasd>] Disk to check whether it is used
      # @return [Boolean] true if the disk is being used
      def used?(disk)
        !(disk.filesystem.nil? && !partitions?(disk) && disk.component_of.empty?)
      end

      def partitions?(device)
        device.respond_to?(:partitions) && !device.partitions.empty?
      end
    end
  end
end
