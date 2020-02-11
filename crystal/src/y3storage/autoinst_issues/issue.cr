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

require "../autoinst_profile"

module Y3Storage
  module AutoinstIssues
    # Base class for storage-ng autoinstallation problems.
    #
    # `Y3Storage::AutoinstIssues` offers an API to register and report storage
    # related AutoYaST problems.
    class Issue
      # Section where it was detected (see {AutoinstProfile})
      def section
        nil
      end

      # Subclass identified by `type`
      #
      # In Ruby, `List#add` relies on `Y2Storage::AutoinstIssues.const_get`. Since there is no
      # `cont_get` in Crystal, this class method is implemented to achieve a similar goal.
      def self.subclass(type)
        class_name = type.to_s.split("_").map(&.capitalize).join

        {{@type.all_subclasses}}.find do |subclass|
          subclass.name.split("::").last == class_name
        end
      end

      # Constructor
      #
      # In the original Ruby code, each subclass of Issue has a completely different constructor
      # with a completely different set of arguments. New objects are instantiated with a generic
      # call like `calculated_class.new(*calculated_args)`... which couldn't be checked by Crystal
      # at compilation if every constructor had a different signature.
      #
      # So we enforce the same signature `initialize(*args)` in all subclasses, which means we
      # have to validate the passed arguments in the body of each constructor.
      def initialize(*args)
      end

      # Return problem severity
      #
      # * :fatal: abort the installation.
      # * :warn:  display a warning.
      #
      # Returns `Symbol` Issue severity (:warn, :fatal)
      # Raises NotImplementedError
      def severity
        raise NotImplementedError.new("#severity")
      end

      # Return the error message to be displayed
      #
      # Returns `String` Error message
      # Raises NotImplementedError
      def message
        raise NotImplementedError.new("#message")
      end

      # Determines whether an error is fatal
      #
      # This is just a convenience method.
      #
      # Returns `Boolean`
      def fatal?
        severity == :fatal
      end

      # Determine whether an error is just a warning
      #
      # This is just a convenience method.
      #
      # Returns `Boolean`
      def warn?
        severity == :warn
      end
    end
  end
end
