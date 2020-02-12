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
    # Represents a problem that occurs when an exception is raised.
    #
    # This error is used as a fallback for any problem that arises during
    # proposal which is not handled in an specific way. It includes the
    # exception which caused the problem to be registered.
    #
    # Example: registering an exception
    #     begin
    #       do_stuff # some exception is raised
    #     rescue e : SomeException
    #       new Y3Storage::AutoinstIssues::Exception.new(e)
    #     end
    class Exception < Issue
      # Exception that was rescued
      getter error : ::Exception

      # Constructor
      #
      # Gets only one argument of type `::Exception`
      def initialize(*args)
        first = args[0]?

        # See `Issue#initialize` for an explanation about why this manual validation is needed
        # instead of declaring the arguments of `#initialize` more explicitly
        if first && first.is_a?(::Exception)
          @error = first
        else
          raise ArgumentError.new("Wrong initialization: #{args}")
        end
      end

      # Return problem severity
      #
      # Returns `Symbol` :fatal
      # See `Issue#severity`
      def severity
        :fatal
      end

      # Return the error message to be displayed
      #
      # Returns `String` Error message
      # See `Issue#message`
      def message
        "A problem ocurred while creating the partitioning plan: %s" % error.message
      end
    end
  end
end
