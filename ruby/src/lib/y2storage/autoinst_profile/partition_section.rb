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
require "y2storage/partition_id"
require "y2storage/filesystems/mount_by_type"
require "y2storage/filesystems/type"
require "y2storage/subvol_specification"

module Y2Storage
  module AutoinstProfile
    # Thin object oriented layer on top of a <partition> section of the
    # AutoYaST profile.
    #
    # More information can be found in the 'Partitioning' section ('Partition
    # Configuration' subsection) of the AutoYaST documentation:
    # https://www.suse.com/documentation/sles-12/singlehtml/book_autoyast/book_autoyast.html#ay.partition_configuration
    # Check that document for details about the semantic of every attribute.
    class PartitionSection < SectionWithAttributes
      # Literal historically used at AutoinstPartPlan
      CRYPT_KEY_VALUE = "ENTER KEY HERE"
      private_constant :CRYPT_KEY_VALUE

      # Partitions with these IDs are historically marked with format=false
      # NOTE: "Dell Utility" was included here, but there is no such ID in the
      # new libstorage.
      NO_FORMAT_IDS = [PartitionId::PREP, PartitionId::DOS16]
      private_constant :NO_FORMAT_IDS

      # Partitions with these IDs are historically marked with create=false
      # NOTE: "Dell Utility" was the only entry here. See above.
      NO_CREATE_IDS = []
      private_constant :NO_CREATE_IDS

      ATTRIBUTES = [
        { name: :create },
        { name: :filesystem },
        { name: :format },
        { name: :label },
        { name: :uuid },
        { name: :lv_name },
        { name: :lvm_group },
        { name: :mount },
        { name: :mountby },
        { name: :partition_id },
        { name: :partition_nr },
        { name: :partition_type },
        { name: :subvolumes },
        { name: :size },
        { name: :crypt_fs },
        { name: :loop_fs },
        { name: :crypt_method },
        { name: :crypt_key },
        { name: :raid_name },
        { name: :raid_options },
        { name: :mkfs_options },
        { name: :fstab_options, xml_name: :fstopt },
        { name: :subvolumes_prefix },
        { name: :create_subvolumes },
        { name: :resize },
        { name: :pool },
        { name: :used_pool },
        { name: :stripes },
        { name: :stripe_size, xml_name: :stripesize },
        { name: :bcache_backing_for },
        { name: :bcache_caching_for },
        { name: :device },
        { name: :btrfs_name }
      ].freeze
      private_constant :ATTRIBUTES

      def self.attributes
        ATTRIBUTES
      end

      define_attr_accessors

      # @!attribute create
      #   @return [Boolean] whether the partition must be created or exists

      # @!attribute crypt_fs
      #   @return [Boolean] whether the partition must be encrypted.
      #   @deprecated Use #crypt_method instead.

      # @!attribute crypt_method
      #   @return [Symbol,nil] encryption method (:luks1, :pervasive_luks2,
      #     :protected_swap, :random_swap or :secure_swap). See {Y2Storage::EncryptionMethod}.

      # @!attribute crypt_key
      #   @return [String] encryption key

      # @!attribute filesystem
      #   @return [Symbol] file system type to use in the partition, it also
      #     influences other fields
      #   @see #type_for_filesystem
      #   @see #id_for_partition

      # @!attribute partition_id
      #   @return [Integer] partition id. See #id_for_partition

      # @!attribute format
      #   @return [Boolean] whether the partition should be formatted

      # @!attribute label
      #   @return [String] label of the filesystem

      # @!attribute uuid
      #   @return [String] UUID of the partition, only useful for reusing
      #     existing filesystems

      # @!attribute lv_name
      #   @return [String] name of the LVM logical volume

      # @!attribute mount
      #   @return [String] mount point for the partition

      # @!attribute mountby
      #   @return [Symbol] :device, :label, :uuid, :path or :id
      #   @see #type_for_mountby

      # @!attribute partition_nr
      #   @return [Integer] the partition number of this partition

      # @!attribute partition_type
      #   @return [String, nil] the partition type of this partition (only can be "primary")

      # @!attribute subvolumes
      #   @return [Array<SubvolSpecification>,nil] list of subvolumes or nil if not
      #     supported (from storage) or not specified (from hashes)

      # @!attribute size
      #   @return [String] size of the partition in the flexible AutoYaST format

      # @!attribute loop_fs
      #   @return [Boolean] undocumented attribute

      # @!attribute raid_name
      #   @return [String] RAID name in which this partition will be included

      # @!attribute raid_options
      #   @return [RaidOptionsSection] RAID options
      #   @see RaidOptionsSection

      # @!attribute mkfs_options
      #   @return [String] mkfs options
      #
      # @!attribute fstab_options
      #   @return [Array<String>] Options to be used in the fstab for the filesystem

      # @!attribute subvolumes_prefix
      #   @return [String] Name of the default Btrfs subvolume

      # @!attribute device
      #   @return [String, nil] undocumented attribute, but used to indicate a NFS
      #     share when installing over NFS (with the old profile format)

      # @!attribute btrfs_name
      #   @return [String] Btrfs in which this partition will be included

      def init_from_hashes(hash)
        super

        if hash["raid_options"]
          @raid_options = RaidOptionsSection.new_from_hashes(hash["raid_options"], self)
        end

        @subvolumes_prefix = hash["subvolumes_prefix"]
        @create_subvolumes = hash.fetch("create_subvolumes", true)
        @subvolumes = subvolumes_from_hashes(hash["subvolumes"]) if hash["subvolumes"]
        @bcache_caching_for = hash.fetch("bcache_caching_for", [])

        @fstab_options = hash["fstopt"].split(",").map(&:strip) if hash["fstopt"]
      end

      # Clones a device into an AutoYaST profile section by creating an instance
      # of this class from the information of a device
      #
      # @see PartitioningSection.new_from_storage for more details
      #
      # @param device [Device] a device that can be cloned into a <partition> section,
      #   like a partition, an LVM logical volume, an MD RAID or a NFS filesystem.
      # @return [PartitionSection]
      def self.new_from_storage(device)
        result = new
        result.init_from_device(device)
        result
      end

      # Filesystem type to be used for the real partition object, based on the
      # #filesystem value.
      #
      # @return [Filesystems::Type, nil] nil if #filesystem is not set or it's
      #   impossible to infer the type
      def type_for_filesystem
        return nil unless filesystem

        Filesystems::Type.find(filesystem)
      rescue NameError
        nil
      end

      # Name schema type to be used for the real partition object, based on the
      # #filesystem value
      #
      # @return [Filesystems::MountByType, nil] nil if #filesystem is not set
      #   or it's impossible to infer the type
      def type_for_mountby
        return nil unless mountby

        Filesystems::MountByType.find(mountby)
      rescue NameError
        nil
      end

      # Partition id to be used for the real partition object.
      #
      # This implements the AutoYaST documented logic. If #partition_id is
      # filled, the corresponding id is used. Otherwise SWAP or LINUX will be
      # used, depending on the value of #filesystem.
      #
      # @return [PartitionId]
      def id_for_partition
        return PartitionId.new_from_legacy(partition_id) if partition_id
        return PartitionId::SWAP if type_for_filesystem&.is?(:swap)

        PartitionId::LINUX
      end

      # Device name to be used for the real MD device
      #
      # This implements the AutoYaST documented logic, if 'raid_name' is
      # provided as one of the corresponding 'raid_options', that name should be
      # used. Otherwise the name will be inferred from 'partition_nr'.
      #
      # @return [String] MD RAID device name
      def name_for_md
        name = raid_options&.raid_name
        return name unless name.nil? || name.empty?

        "/dev/md/#{partition_nr}"
      end

      # Name to reference a multi-device Btrfs (used when exporting).
      #
      # @param filesystem [Filesystems::BlkFilesystem, nil]
      # @return [String, nil]
      def name_for_btrfs(filesystem)
        return nil unless filesystem&.multidevice? && filesystem&.is?(:btrfs)

        "btrfs_#{filesystem.sid}"
      end

      def to_hashes
        hash = super
        hash["fstopt"] = fstab_options.join(",") if fstab_options && !fstab_options.empty?
        if subvolumes
          hash["create_subvolumes"] = !subvolumes.empty?
          hash["subvolumes"] = subvolumes_to_hashes
          hash["subvolumes_prefix"] = subvolumes_prefix
        end
        hash
      end

      # Return section name
      #
      # @return [String] "partitions"
      def section_name
        "partitions"
      end

      protected

      # Uses legacy ids for backwards compatibility. For example, BIOS Boot
      # partitions in the old libstorage were represented by the internal
      # code 259 and, thus, systems cloned with the old exporter
      # (AutoinstPartPlan) use 259 instead of the current 257.
      def partition_id_from(partition)
        id = enforce_bios_boot?(partition) ? PartitionId::BIOS_BOOT : partition.id
        id.to_i_legacy
      end

      # Whether the given existing partition should be reported as GRUB (GPT
      # Bios Boot) in the cloned profile.
      #
      # @note To ensure backward compatibility, this method implements the
      # logic present in the old AutoYaST exporter that used to live in
      # AutoinstPartPlan#ReadHelper.
      # https://github.com/yast/yast-autoinstallation/blob/47c24fb98e074f5b6432f3a4f8b9421362ee29cc/src/modules/AutoinstPartPlan.rb#L345
      # Thus, this returns true for any partition with a Windows-related ID
      # that is configured to be mounted in /boot*
      # See commit 54e236cd428636b3bf8f92d2ac2914e5b1d67a90 of
      # yast-autoinstallation.
      #
      # @param partition [Partition]
      # @return [Boolean]
      def enforce_bios_boot?(partition)
        return false if partition.filesystem_mountpoint.nil?

        partition.id.is?(:windows_system) && partition.filesystem_mountpoint.include?("/boot")
      end

      # Returns an array of hashes representing subvolumes
      #
      # AutoYaST only uses a subset of subvolumes properties: 'path' and 'copy_on_write'.
      #
      # @return [Array<Hash>] Array of hash-based representations of subvolumes
      def subvolumes_to_hashes
        subvolumes.map do |subvol|
          subvol_path = subvol.path.sub(/\A#{@subvolumes_prefix}\//, "")
          { "path" => subvol_path, "copy_on_write" => subvol.copy_on_write }
        end
      end

      # Return a list of subvolumes from an array of hashes
      #
      # This method builds a list of SubvolSpecification objects from an array
      # of subvolumes in hash form (according to AutoYaST specification).
      #
      # Additionally, it filters out "@" subvolumes entries which were
      # generated by older AutoYaST versions. See bnc#1061253.
      #
      # @param hashes [Array<Hash>] List of subvolumes in hash form
      # @return [Array<SubvolSpecification>] List of subvolumes
      def subvolumes_from_hashes(hashes)
        subvolumes = SubvolSpecification.list_from_control_xml(hashes)
        subvolumes.reject { |s| s.path == "@" }
      end

      # Returns the volume group associated to a given device
      #
      # @param device [Y2Storage::Partition,Y2Storage::Md] Partition or MD RAID device.
      # @return [String,nil] Volume group; nil if it is not used as a physical volume or does
      #   not belong to any volume group.
      def lvm_group_name(device)
        return nil if device.lvm_pv.nil? || device.lvm_pv.lvm_vg.nil?

        device.lvm_pv.lvm_vg.basename
      end

      # Determines whether the device has a fixed size (disk, RAID, etc.)
      #
      # It is used to find out whether the size specification should be included
      # in the profile.
      #
      # @param device [Y2Storage::Device] Device
      # @return [Boolean]
      def fixed_size?(device)
        device.is?(:disk_device, :software_raid)
      end

      # Determines whether given partition is primary or not
      #
      # Always false when the partition table does not allow extended partitions
      #
      # @param partition [Y2Storgae::Partition] the partition to check
      # @return [Boolean] true when is a primary partition; false otherwise
      def primary_partition?(partition)
        return false unless partition.partition_table.extended_possible?

        partition.type.is?(:primary)
      end
    end
  end
end
