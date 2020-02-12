# Copyright (c) [2012-2016] Novell, Inc.
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
  # Helper class to represent a subvolume specification as defined
  # in control.xml
  #
  class SubvolSpecification
    attr_accessor :path, :copy_on_write, :archs

    COW_SUBVOL_PATHS = [
      "home",
      "opt",
      "srv",
      "tmp",
      "usr/local",
      "var/cache",
      "var/crash",
      "var/lib/machines",
      "var/lib/mailman",
      "var/lib/named",
      "var/log",
      "var/opt",
      "var/spool",
      "var/tmp",
      "boot/grub2/i386-pc",
      "boot/grub2/x86_64-efi",
    ]

    # No Copy On Write for SQL databases and libvirt virtual disks to
    # minimize performance impact
    NO_COW_SUBVOL_PATHS = [
      "var/lib/libvirt/images",
      "var/lib/mariadb",
      "var/lib/mysql",
      "var/lib/pgsql"
    ]

    # Subvolumes, from the lists above, that contain architecture modifiers
    SUBVOL_ARCHS = {
      "boot/grub2/i386-pc"          => ["i386", "x86_64"],
      "boot/grub2/x86_64-efi"       => ["x86_64"],
    }

    def initialize(path, copy_on_write: true, archs: nil)
      @path = path
      @copy_on_write = copy_on_write
      @archs = archs
    end

    def to_s
      text = "SubvolSpecification #{@path}"
      text += " (NoCOW)" unless @copy_on_write
      text
    end

    def arch_specific?
      !archs.nil?
    end

    # Comparison operator for sorting
    #
    def <=>(other)
      path <=> other.path
    end

    # Check if this subvolume should be used for the current architecture.
    # A subvolume is used if its archs contain the current arch.
    # It is not used if its archs contain the current arch negated
    # (e.g. "!ppc").
    #
    # @return [Boolean] true if this subvolume matches the current architecture
    #
    def current_arch?
      true
    end

    # Check if this subvolume should be used for an architecture.
    #
    # If a block is given, the block is called as the matcher with the
    # architecture to be tested as its argument.
    #
    # If no block is given (and only then), the 'target_arch' parameter is
    # used to check against.
    #
    # @return [Boolean] true if this subvolume matches
    #
    def matches_arch?(target_arch = nil, &block)
      return true unless arch_specific?

      use_subvol = false
      archs.each do |a|
        arch = a.dup
        negate = arch.start_with?("!")
        arch[0] = "" if negate # remove leading "!"
        match = block_given? ? block.call(arch) : arch == target_arch
        if match && negate
          return false
        end
        use_subvol ||= match
      end
      use_subvol
    end

    # Factory method: Create one SubvolSpecification from XML data.
    #
    # @param xml [Hash,String] can be a map (for fully specified subvolumes)
    #   or just a string (for subvolumes specified just as a path)
    # @return [SubvolSpecification] or nil if error
    def self.create_from_xml(xml)
      return nil if xml.nil?

      xml = { "path" => xml } if xml.is_a?(String)
      return nil unless xml.key?("path")

      path = xml["path"]
      cow = true
      cow = xml["copy_on_write"] if xml.key?("copy_on_write")
      archs = nil
      archs = xml["archs"].gsub(/\s+/, "").split(",") if xml.key?("archs")
      planned_subvol = SubvolSpecification.new(path, copy_on_write: cow, archs: archs)
      planned_subvol
    end

    # Create a SubvolSpecification from a Btrfs subvolume
    #
    # @param subvolume [BtrfsSubvolume] Btrfs subvolume
    # @return [SubvolSpecification]
    def self.create_from_btrfs_subvolume(subvolume)
      subvol = SubvolSpecification.new(subvolume.path, copy_on_write: !subvolume.nocow?)
      subvol
    end

    # Create a list of SubvolSpecification objects from the <subvolumes> part of
    # control.xml or an AutoYaST profile. The map may be empty if there is a
    # <subvolumes> section, but that section is empty.
    #
    # Returns nil if the section is nil or impossible to process.
    #
    # This function does not do much error handling or reporting; it is assumed
    # that control.xml and/or the AutoYaST profile are validated against the
    # corresponding schema.
    #
    # Note that the AutoYaST format is a superset of the control.xml one,
    # accepting fully described subvolumes (like in control.xml) and also
    # subvolumes specified as a simple path.
    #
    # @param subvolumes_xml [Array] list of XML <subvolume> entries
    # @return [Array<SubvolSpecification>, nil]
    def self.list_from_control_xml(subvolumes_xml)
      return nil if subvolumes_xml.nil?
      return nil unless subvolumes_xml.respond_to?(:map)

      subvols = subvolumes_xml.each_with_object([]) do |xml, result|
        # Remove nil subvols due to XML parse errors
        next if xml.nil?

        new_subvol = SubvolSpecification.create_from_xml(xml)
        next if new_subvol.nil?

        result << new_subvol
      end
      subvols.sort!
    end

    # Create a fallback list of subvol specifications. This is useful if
    # nothing is specified in the control.xml file.
    #
    # @return [Array<SubvolSpecification>]
    def self.fallback_list
      subvols = COW_SUBVOL_PATHS.map { |path| SubvolSpecification.new(path) }
      subvols.concat(
        NO_COW_SUBVOL_PATHS.map { |path| SubvolSpecification.new(path, copy_on_write: false) }
      )
      subvols.each { |subvol| subvol.archs = SUBVOL_ARCHS[subvol.path] }
      subvols.sort!
    end

    # Filters specs and returns only what makes sense for the current architecture
    #
    # @see #current_arch?
    #
    # @param specs [Array<SubvolSpecification>]
    # @return [Array<SubvolSpecification>]
    def self.for_current_arch(specs)
      specs.select(&:current_arch?)
    end
  end
end
