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
  # Y3Storage::AutoinstIssues offers an API to register and report storage
  # related AutoYaST problems.
  #
  # Basically, it works by registering found problems when creating the
  # partitioning proposal (based on AutoYaST profile) and displaying them to
  # the user. Check `Y3Storage::AutoinstIssues::Issue` in order to
  # find out more details about the kind of problems.
  #
  # About registering errors, an instance of the
  # `Y3Storage::AutoinstIssues::List` will be used.
  module AutoinstIssues
  end
end

require "./autoinst_issues/list"
require "./autoinst_issues/issue"
require "./autoinst_issues/exception"
require "./autoinst_issues/invalid_encryption"
require "./autoinst_issues/invalid_value"
require "./autoinst_issues/missing_root"
