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

require "y2storage/autoinst_profile/drive_section"

module Y2Storage
  module AutoinstProfile
    # Thin object oriented layer on top of the <partitioning> section of the
    # AutoYaST profile.
    #
    # More information can be found in the 'Partitioning' section of the AutoYaST documentation:
    # https://www.suse.com/documentation/sles-12/singlehtml/book_autoyast/book_autoyast.html#CreateProfile.Partitioning
    class PartitioningSection
      # @return [Array<DriveSection] drives whithin the <partitioning> section
      attr_accessor :drives

      def initialize
        @drives = []
      end

      # Returns the parent section
      #
      # This method only exist to conform to other sections API (like classes
      # derived from {SectionWithAttributes}).
      #
      # @return [nil]
      def parent
        nil
      end

      # Creates an instance based on the profile representation used by the
      # AutoYaST modules (nested arrays and hashes).
      #
      # This method provides no extra validation, type conversion or
      # initialization to default values. Those responsibilities belong to the
      # AutoYaST modules. The collection of hashes is expected to be valid and
      # contain the relevant information.
      #
      # @param drives_array [Array<Hash>] content of the "partitioning" section
      #   of the main profile hash. Each element of the array represents a
      #   drive section in that profile.
      # @return [PartitioningSection]
      def self.new_from_hashes(drives_array)
        result = new
        result.drives = drives_array.each_with_object([]) do |hash, array|
          drive = DriveSection.new_from_hashes(hash, result)
          array << drive if drive
        end
        result
      end

      # Content of the section in the format used by the AutoYaST modules
      # (nested arrays and hashes).
      #
      # @return [Array<Hash>] each element represents a <drive> section
      def to_hashes
        drives.map(&:to_hashes)
      end

      DISK_DRIVE_TYPES = [:CT_DISK, :CT_DMMULTIPATH].freeze
      private_constant :DISK_DRIVE_TYPES

      # Drive sections with type :CT_DISK
      #
      # @return [Array<DriveSection>]
      def disk_drives
        drives.select { |d| DISK_DRIVE_TYPES.include?(d.type) }
      end

      # Drive sections with type :CT_LVM
      #
      # @return [Array<DriveSection>]
      def lvm_drives
        drives.select { |d| d.type == :CT_LVM }
      end

      # Drive sections with type :CT_MD
      #
      # @return [Array<DriveSection>]
      def md_drives
        drives.select { |d| d.type == :CT_MD }
      end

      # Drive sections with type :CT_BCACHE
      #
      # @return [Array<DriveSection>]
      def bcache_drives
        drives.select { |d| d.type == :CT_BCACHE }
      end

      # Drive sections with type :CT_NFS
      #
      # @return [Array<DriveSection>]
      def nfs_drives
        drives.select { |d| d.type == :CT_NFS }
      end

      # Drive sections with type :CT_BTRFS
      #
      # @return [Array<DriveSection>]
      def btrfs_drives
        drives.select { |d| d.type == :CT_BTRFS }
      end

      # Return section name
      #
      # @return [String] "partitioning"
      def section_name
        "partitioning"
      end
    end
  end
end
