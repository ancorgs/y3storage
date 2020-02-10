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

require "./issue"

module Y3Storage
  module AutoinstIssues
    # List of storage related AutoYaST problems
    #
    # Example: Registering some problems
    #     section = PartitionSection.new({})
    #     list = List.new
    #     list.add(:missing_root)
    #     list.add(:invalid_value, section, :size, "auto")
    #
    # Example: Iterating through the list of problems
    #     list.map(&:severity) #=> [:warn]
    class List
      include Enumerable(Issue)

      delegate :each, :empty?, :<<, to: @items

      # Constructor
      def initialize
        @items = [] of Issue
      end

      # Add a problem to the list
      #
      # The type of the problem is identified as a symbol which name is the
      # underscore version of the class which implements it. For instance,
      # `MissingRoot` would be referred as `:missing_root`.
      #
      # If a given type of problem requires some additional arguments, they
      # should be added when calling this method. See the next example.
      #
      # Example: Adding a problem with additional arguments
      #     list = List.new
      #     list.add(:invalid_value, "/", :size, "auto")
      #     list.empty? #=> false
      #
      # Param type       `Symbol` Issue type
      # Param extra_args `Array` Additional arguments for the given problem
      # Returns `Array<Issue>` List of problems
      def add(type, *extra_args)
        klass = Issue.subclass(type)
        if klass
          self << klass.new(*extra_args)
        else
          raise Error.new("Unknown AutoInstIssue type")
        end
      end

      # Determine whether any of the problem on the list is fatal
      #
      # Returns `Boolean` true if any of them is a fatal problem
      def fatal?
        any?(&.fatal?)
      end

      # Returns an array containing registered problems
      #
      # Returns `Array<Issue>` List of problems
      def to_a
        @items
      end
    end
  end
end
