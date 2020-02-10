# Copyright (c) [2019-2020] SUSE LLC
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
    # Represents an AutoYaST situation where an invalid value was given.
    #
    # Example: invalid value 'auto' for attribute :size on /home partition
    #     section = AutoinstProfile::PartitioningSection.new_from_hashes({"size" => "auto"})
    #     problem = InvalidValue.new(section, :size, section.size)
    #     problem.value #=> "auto"
    #     problem.attr  #=> :size
    class InvalidValue < Issue
      # Section where it was detected (see {AutoinstProfile})
      getter section : AutoinstProfile::PartitionSection | AutoinstProfile::SkipListSection

      # Name of the missing attribute
      getter attr : Symbol

      # Invalid value
      getter value : Int64 | String

      # New value or :skip to skip the section.
      getter new_value : Int64 | String | Symbol

      # Constructor
      #
      # Gets several arguments
      #
      #   * `section` Section where it was detected (see `AutoinstProfile`)
      #   * `attr` Name of the invalid attribute (as symbol)
      #   * `value` Invalid value
      #   * `new_value` (optional) New value or :skip to skip the section
      def initialize(*args)
        first = args[0]?
        second = args[1]?
        third = args[2]?

        if first.is_a?(typeof(@section)) && second.is_a?(Symbol) && third.is_a?(typeof(@value))
          @section = first
          @attr = second
          @value = third

          @new_value = args[3]? || :skip
        else
          raise ArgumentError.new("Wrong initialization: #{args}")
        end
      end

      # Return problem severity
      #
      # Returns `Symbol` :warn
      # See `Issue#severity`
      def severity
        :warn
      end

      # Return the error message to be displayed
      #
      # Returns `String` Error message
      # See `Issue#message`
      def message
        # TRANSLATORS: 'value' is a generic value (number or string) 'attr' is an AutoYaST element
        # name; 'new_value_message' is a short explanation about what should be done with the value.
        "Invalid value '%{value}' for attribute '%{attr}' (%{new_value_message})." %
          {
            value:             value,
            attr:              attr,
            new_value_message: new_value_message,
          }
      end

      # Return a messsage explaining what should be done with the value.
      private def new_value_message
        if new_value == :skip
          # TRANSLATORS: it refers to an AutoYaST profile section
          "the section will be skipped"
        else
          # TRANSLATORS: 'value' is the value for an AutoYaST element (a number or a string)
          "replaced by '%{value}'" % {value: new_value}
        end
      end
    end
  end
end
