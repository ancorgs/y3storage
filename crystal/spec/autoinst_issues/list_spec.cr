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

Spectator.describe Y3Storage::AutoinstIssues::List do
  subject(:list) { described_class.new }
  let(:section) { Y3Storage::AutoinstProfile::SkipListSection.new }

  describe "#add" do
    it "adds a new issue to the list" do
      list.add(:exception, NilAssertionError.new)
      expect(list.to_a).to all(be_an(Y3Storage::AutoinstIssues::Exception))
    end

    mock Y3Storage::AutoinstIssues::InvalidValue do
      stub self.new(*args)
    end

    it "pass extra arguments to issue instance constructor" do
      expect(Y3Storage::AutoinstIssues::InvalidValue).to receive(:new).with(section, :size, "value")
      list.add(:invalid_value, section, :size, "value")
    end
  end

  describe "#to_a" do
    context "when list is empty" do
      it "returns an empty array" do
        expect(list.to_a).to eq([] of Y3Storage::AutoinstIssues::Issue)
      end
    end

    context "when some issue was added" do
      before_each do
        2.times { list.add(:exception, NilAssertionError.new) }
      end

      it "returns an array containing added issues" do
        expect(list.to_a).to all(be_a(Y3Storage::AutoinstIssues::Exception))
        expect(list.to_a.size).to eq(2)
      end
    end
  end

  describe "#empty?" do
    context "when list is empty" do
      it "returns true" do
        expect(list).to be_empty
      end
    end

    context "when some issue was added" do
      before_each { list.add(:exception, NilAssertionError.new) }

      it "returns false" do
        expect(list).to_not be_empty
      end
    end
  end

  describe "#fatal?" do
    context "when contains some fatal error" do
      before_each { list.add(:missing_root) }

      it "returns true" do
        expect(list).to be_fatal
      end
    end

    context "when contains some fatal error" do
      before_each { list.add(:invalid_value, section, :size, "value") }

      it "returns false" do
        expect(list).to_not be_fatal
      end
    end
  end
end
