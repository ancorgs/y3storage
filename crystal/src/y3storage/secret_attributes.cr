# Copyright (c) [2017-2020] SUSE LLC
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

module Y3Storage
  # Mixin that enables a class to define attributes that are never exposed via
  #   #inspect, #to_s or similar methods, with the goal of preventing
  #   unintentional leaks of sensitive information in the application logs.
  module SecretAttributes
    # Inner class to store the value of the attribute without exposing it
    # directly
    class Attribute
      # TODO: this is not generic enough
      getter value : String

      def initialize(value)
        @value = value
      end

      def to_s
        value.nil? ? "" : "<secret>"
      end

      def inspect(io)
        io.puts "<secret>"
      end

      def instance_variables
        # This adds even an extra barrier, just in case some formatter tries to
        # use deep instrospection
        [] of String
      end
    end
  end
end

# Similar to .attr_accessor but with additional mechanisms to prevent
# exposing the internal value of the attribute
#
# @example
#   class TheClass
#     include Y2Storage::SecretAttributes
#
#     attr_accessor :name
#     secret_attr :password
#   end
#
#   one_object = TheClass.new
#   one_object.name = "Aa"
#   one_object.password = "42"
#
#   one_object.password # => "42"
#   one_object.inspect # => "#<TheClass:0x0f8 @password=<secret>, @name=\"Aa"\">"
macro secret_attr(name)
  class {{@type}}
    @{{name.id}} = Attribute.new("")

    def {{name.id}}
      attribute = @{{name.id}}
      attribute ? attribute.value : nil
    end

    def {{name.id}}= (value)
      @{{name.id}} = Attribute.new(value)
      value
    end
  end
end
