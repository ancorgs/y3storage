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

require "../spec_helper"

Spectator.describe Y3Storage::AutoinstIssues::InvalidEncryption do
  mock Y3Storage::AutoinstProfile::PartitionSection do
    stub crypt_method
  end

  let(:crypt_method) { :luks1 }
  let(:reason) { :unknown }
  let(:section) { Y3Storage::AutoinstProfile::PartitionSection.new }

  subject(:issue) { described_class.new(section, reason) }

  before_each { allow(section).to receive(:crypt_method).and_return crypt_method }

  describe "#message" do
    context "when method is unknown" do
      let(:reason) { :unknown }
      let(:crypt_method) { :foo }

      it "warns about the method being unknown" do
        message = issue.message
        expect(message).to match(/'foo' is not a known/)
      end
    end

    context "when method is unavailable" do
      let(:reason) { :unavailable }
      let(:crypt_method) { :pervasive_luks2 }

      it "warns about the method not being available" do
        message = issue.message
        expect(message).to match(/'pervasive_luks2' is not available/)
      end
    end

    context "when method is unsuitable" do
      let(:reason) { :unsuitable }
      let(:crypt_method) { :pervasive_luks2 }

      it "warns about the method not being suitable" do
        message = issue.message
        expect(message).to match(/'pervasive_luks2' is not a suitable/)
      end
    end
  end

  describe "#severity" do
    it "returns :fatal" do
      expect(issue.severity).to eq(:fatal)
    end
  end
end
