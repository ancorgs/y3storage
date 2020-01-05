#!/usr/bin/env ruby
#
# encoding: utf-8

# Copyright (c) [2016-2020] SUSE LLC
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

require "../disk_size"

module Y3Storage
  module Refinements
    # Equivalent to the Ruby's refinement Y2Storage::Refinements::SizeCasts to
    # make the creation of DiskSize objects more readable
    #
    # There are no refinements (or fully equivalent concept) in Crystal. But adding
    # methods via monkey patching is safer than in Ruby (as long as the types are
    # explicitly specified) because Crystal uses method overloading.
    #
    # This is encapsulated in a module just for symmetry with the Ruby code and
    # for documentation purposes. In fact, this will globally modify the
    # Crystal numeric classes as soon as this file is required.
    #
    # This adds methods to perform a direct cast from numerical classes into
    # DiskSize objects.
    #
    # Example:
    #     20.gib == Y3Storage::DiskSize.gib(20)
    #     12.5.mib == Y3Storage::DiskSize.mib(12.5)
    module SizeCasts
      ADDED_METHODS = [
        :kib, :mib, :gib, :tib, :pib, :eib, :zib, :yib,
        :kb, :mb, :gb, :tb, :pb, :eb, :zb, :yb
      ]

      struct ::Number
        {% for meth in Y3Storage::Refinements::SizeCasts::ADDED_METHODS %}
          # Creates a `Y3Storage::DiskSize` object
          #
          # Example: this is equivalent to `Y3Storage::DiskSize.{{meth.id}}(4)
          #   4.{{meth.id}}
          def {{meth.id}} : Y3Storage::DiskSize
            Y3Storage::DiskSize.{{meth.id}}(self)
          end
        {% end %}
      end
    end
  end
end
