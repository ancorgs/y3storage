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

require "../spec_helper"

Spectator.describe Y3Storage::AutoinstIssues::InvalidValue do
  mock Y3Storage::AutoinstProfile::PartitionSection do
    stub size { "auto" }
  end

  subject(:issue) { described_class.new(section, :size, "auto") }

  let(:section) { Y3Storage::AutoinstProfile::PartitionSection.new }

  describe "#message" do
    it "includes relevant information" do
      message = issue.message
      expect(message).to contain "size"
      expect(message).to contain "auto"
    end

    context "when no new value was given" do
      it "includes a warning about the section being skipped" do
        expect(issue.message).to contain "the section will be skipped"
      end
    end

    context "when a new value was given" do
      subject(:issue) { described_class.new(section, :size, "auto", "some-value") }

      it "includes a warning about the section being skipped" do
        expect(issue.message).to contain "replaced by 'some-value'"
      end
    end

    context "when :skip is given as new value" do
      subject(:issue) { described_class.new(section, :size, "auto", :skip) }

      it "includes a warning about the section being skipped" do
        expect(issue.message).to contain "the section will be skipped"
      end
    end
  end

  describe "#severity" do
    it "returns :warn" do
      expect(issue.severity).to eq(:warn)
    end
  end
end
