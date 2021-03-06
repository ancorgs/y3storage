# Copyright (c) [2016-2017] SUSE LLC
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
  VERSION = "0.1.0"
end

require "./y3storage/exceptions"
require "./y3storage/disk_size"
require "./y3storage/autoinst_profile"
require "./y3storage/autoinst_issues"
require "./y3storage/refinements"
require "./y3storage/secret_attributes"
require "./y3storage/subvol_specification"
