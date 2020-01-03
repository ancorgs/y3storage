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
  module Filesystems
    class MountByType
      def initialize(id)
        @id = id
      end

      DEVICE = new(:device)
      UUID = new(:uuid)

      ALL = [DEVICE, UUID]
      private_constant :ALL

      def to_sym
        @id
      end

      def is?(symbol)
        to_sym == symbol
      end

      def self.find(sym)
        ALL.find { |t| t.to_sym == sym }
      end
    end
  end
end
