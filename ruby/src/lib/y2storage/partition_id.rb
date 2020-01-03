# Copyright (c) [2017] SUSE LLC
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

module Y2Storage
  # Class to represent all the possible partition ids
  #
  # This is a wrapper for the Storage::ID enum
  class PartitionId
    def initialize(id, symbol)
      @id = id
      @symbol = symbol
    end

    def to_i
      @id
    end

    def to_s
      @symbol
    end

    BIOS_BOOT          = new(0x101, :bios_boot)
    DIAG               = new(0x12, :diag)
    DOS12              = new(0x01, :dos12)
    DOS16              = new(0x06, :dos16)
    DOS32              = new(0x0c, :dos32)
    ESP                = new(0xef, :esp)
    EXTENDED           = new(0x0f, :extended)
    IRST               = new(0x84, :irst)
    LINUX              = new(0x83, :linux)
    LVM                = new(0x8e, :lvm)
    MICROSOFT_RESERVED = new(0x103, :microsoft_reserved)
    NTFS               = new(0x07, :ntfs)
    PREP               = new(0x41, :prep)
    RAID               = new(0xfd, :raid)
    SWAP               = new(0x82, :swap)
    UNKNOWN            = new(0x100, :unknown)
    WINDOWS_BASIC_DATA = new(0x102, :windows_basic_data)

    ALL = [
      BIOS_BOOT, DIAG, DOS12, DOS16, DOS32, ESP, EXTENDED, IRST, LINUX, LVM,
      MICROSOFT_RESERVED, NTFS, PREP, RAID, SWAP, UNKNOWN, WINDOWS_BASIC_DATA
    ]
    private_constant :ALL

    NOT_ALLOW_FORMAT = [LVM, RAID, ESP, PREP, BIOS_BOOT, UNKNOWN].freeze
    private_constant :NOT_ALLOW_FORMAT

    SORT_ORDER = [
      # Linux partition IDs first
      LINUX,
      SWAP,
      LVM,
      RAID,
      # Boot-related
      ESP,
      BIOS_BOOT,
      PREP,
      # Windows-related
      NTFS,
      DOS32,
      DOS16,
      DOS12,
      WINDOWS_BASIC_DATA,
      MICROSOFT_RESERVED,
      # Other
      IRST,
      DIAG,
      EXTENDED
      # Eveything not listed here is sorted after this
    ].freeze

    private_constant :SORT_ORDER

    def formattable?
      !NOT_ALLOW_FORMAT.include?(to_sym)
    end

    LINUX_SYSTEM_IDS = [LINUX, SWAP, LVM, RAID]

    WINDOWS_SYSTEM_IDS = [NTFS, DOS32, DOS16, DOS12, WINDOWS_BASIC_DATA, MICROSOFT_RESERVED]

    private_constant :LINUX_SYSTEM_IDS, :WINDOWS_SYSTEM_IDS

    # Partition ids for which the internal numeric id is the same than the
    # corresponding fsid in the old libstorage.
    # See {.new_from_legacy} and {#to_i_legacy}.
    LEGACY_KEPT = [DOS12, DOS16, DOS32, NTFS, EXTENDED, PREP, LINUX, SWAP, LVM, RAID, DIAG, ESP]

    # Matching between fsids in the old libstorage and the corresponding
    # partition id.
    # See {.new_from_legacy} and {#to_i_legacy}.
    LEGACY_TO_CURRENT = {
      4   => DOS16, # Known as "FAT16 <32M"
      5   => EXTENDED, # In the past both 5 and 15 were recognized as extended
      11  => DOS32, # Known as "Win95 FAT32" as an alternative to 0x0c (Win95 FAT32 LBA)
      14  => DOS16, # Known as "Win95 FAT16" as an alternative to 0x06 (FAT16)
      257 => UNKNOWN, # 257 used to mean mac_hidden, but is BIOS_BOOT now
      258 => UNKNOWN, # 258 used to mean mac_hfs, but is WINDOWS_BASIC_DATA now
      259 => ESP, # 259 is MICROSOFT_RESERVED now
      261 => MICROSOFT_RESERVED,
      263 => BIOS_BOOT,
      264 => PREP
    }

    # Matching between partition ids and the number that was used to represent
    # them in the old libstorage.
    # See {.new_from_legacy} and {#to_i_legacy}.
    CURRENT_TO_LEGACY = {
      BIOS_BOOT.to_i          => 263, # BIOS_BOOT.to_i is 257, that used to mean mac_hidden
      ESP.to_i                => 259, # ESP.to_i is 239, that used to have no special meaning
      WINDOWS_BASIC_DATA.to_i => 0, # WINDOWS_BASIC_DATA.to_i is 258, that used to mean mac_hfs
      MICROSOFT_RESERVED.to_i => 261 # MICROSOFT_RESERVED.to_i is 261, that used to mean BIOS_BOOT
    }
    private_constant :LEGACY_KEPT, :LEGACY_TO_CURRENT, :CURRENT_TO_LEGACY

    # Partition id that was represented by the given numeric fsid in the old
    # libstorage.
    #
    # @param number [Integer] fsid used in the old libstorage
    # @return [PartitionId] corresponding id. UNKNOWN if there is no equivalent
    def self.new_from_legacy(number)
      return LEGACY_TO_CURRENT[number] if LEGACY_TO_CURRENT.key?(number)
      return ALL.find { |id| id.to_i == number } if LEGACY_KEPT.map(&:to_i).include?(number)

      UNKNOWN
    end

    # Numeric fsid used in the old libstorage to represent this partition id.
    #
    # @return [Integer]
    def to_i_legacy
      return CURRENT_TO_LEGACY[to_i] if CURRENT_TO_LEGACY.key?(to_i)

      to_i
    end

    # Set of ids for partitions that are typically part of a Linux system.
    # This may be a normal Linux partition (type 0x83), a Linux swap partition
    # (type 0x82), an LVM partition, or a RAID partition.
    #
    # @return [Array<PartitionId>]
    def self.linux_system_ids
      LINUX_SYSTEM_IDS.dup
    end

    # Set of ids for partitions that could potentially host a MS Windows system.
    #
    # Take into account that checking the partition id is not enough to ensure a
    # partition is suitable to host a MS Windows installation (for example,
    # Windows can only be installed in primary partitions).
    #
    # @return [Array<PartitionId>]
    def self.windows_system_ids
      WINDOWS_SYSTEM_IDS.dup
    end

    # @see StorageEnumWrapper#is?
    #
    # In addition to checking by name, it also supports :linux_system and
    # :windows_system
    #
    # @see .linux_system_ids
    # @see .windows_system_ids
    def is?(*names)
      names.any? do |name|
        case name.to_sym
        when :linux_system
          LINUX_SYSTEM_IDS.include?(self)
        when :windows_system
          WINDOWS_SYSTEM_IDS.include?(self)
        else
          name.to_sym == to_sym
        end
      end
    end

    # Get the sort order of this partition ID.
    # @return [Integer]
    def sort_order
      SORT_ORDER.find_index(self) || SORT_ORDER.size
    end

    # Comparison operator for sorting.
    # @return [Integer] -1, 0, 1
    def <=>(other)
      return -1 unless other.respond_to?(:sort_order)

      sort_order <=> other.sort_order
    end
  end
end
