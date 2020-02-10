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
  # Namespace adding an OOP layer on top of the <partitioning> section of the
  # AutoYaST profile and its subsections.
  #
  # At some point, it would probably make sense to move all the contained
  # classes from Y2Storage to AutoYaST.
  module AutoinstProfile
  end
end

require "./autoinst_profile/partition_section"
require "./autoinst_profile/skip_list_section"
