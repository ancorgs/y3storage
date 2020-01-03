# Copyright (c) [2016-2019] SUSE LLC
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

# Set the paths
TEST_PATH = File.expand_path(__dir__)
$LOAD_PATH.unshift File.expand_path('../../src/lib', __FILE__)

# make sure we run the tests in English locale
# (some tests check the output which is marked for translation)
ENV["LC_ALL"] = "en_US.UTF-8"

require "rspec"
require "y2storage"
