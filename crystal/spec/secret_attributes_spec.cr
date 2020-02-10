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

require "./spec_helper"

Spectator.describe Y3Storage::SecretAttributes do
  # Dummy test class
  class ClassWithPassword
    property name : String | Nil
    Y3Storage.secret_attr :password
  end

  # Another dummy test clase
  class ClassWithData
    property name : String | Nil
    Y3Storage.secret_attr :data
  end

  # Hypothetical custom formatter that uses instrospection to directly query the
  # internal state of the object, ignoring the uniform access principle.
  # def custom_formatter(object)
  #   object.instance_variables.each_with_object("") do |var, result|
  #     result << "@#{var}: #{object.instance_variable_get(var)};\n"
  #   end
  # end

  let(:with_password) { ClassWithPassword.new }
  let(:with_password2) { ClassWithPassword.new }
  let(:with_data) { ClassWithData.new }
  let(:ultimate_hash) { { ultimate_question: 42 } }

  describe ".secret_attr" do
    it "provides a getter returning nil by default" do
      expect(with_password.password).to be_nil
      expect(with_data.data).to be_nil
    end

    it "provides a setter" do
      with_password.password = "super-secret"
      expect(with_password.password).to eq "super-secret"
    end

    # does not make sense in crystal which do method check in compile time
    # it "only adds the setter and getter to the correct class" do
    #   expect { with_password.data }.to raise_error NoMethodError
    #   expect { with_data.password }.to raise_error NoMethodError
    #   expect { with_password.data = 2 }.to raise_error NoMethodError
    #   expect { with_data.password = "xx" }.to raise_error NoMethodError
    # end

    it "does not mess attributes of different instances" do
      with_password.password = "super-secret"
      with_password2.password = "not so secret"
      expect(with_password.password).to eq "super-secret"
      expect(with_password2.password).to eq "not so secret"
    end

# TODO: so far only string attrs supported
#    it "does not modify #inspect for the attribute" do
#      expect(with_data.data.inspect).to eq "nil"
#
#      with_data.data = ultimate_hash
#
#      expect(with_data.data.inspect).to eq ultimate_hash.inspect
#    end

#   it "does not modify #to_s for the attribute" do
#     expect(with_data.data.to_s).to eq ""
#
#      with_data.data = ultimate_hash
#
#      expect(with_data.data.to_s).to eq ultimate_hash.to_s
#    end

#    it "does not modify interpolation for the attribute" do
#      expect("String: #{with_data.data}").to eq "String: "
#
#      with_data.data = ultimate_hash
#
#      expect("String: #{with_data.data}").to eq "String: #{ultimate_hash}"
#    end

    it "is copied in dup just like .property" do
      with_password.name = "data1"
      with_password.password = "xxx"
      duplicate = with_password.dup

      expect(duplicate.name).to eq "data1"
      expect(duplicate.password).to eq "xxx"

      duplicate.password = "yyy"
      expect(duplicate.password).to eq "yyy"
      expect(with_password.password).to eq "xxx"

      with_password2.name = "data2"
      with_password2.password = "xx2"
    end

    context "when the attribute has never been set" do
      it "is displayed as nil in #inspect (like .property)" do
        expect(with_password.inspect).to contain "@name=nil"
        expect(with_password.inspect).to contain "@password=nil"
      end

      it "is displayed as nil by pp (like .property)" do
        expect(with_password.inspect).to contain "@name=nil"
        expect(with_password.inspect).to contain "@password=nil"
      end

      # it "is not exposed to formatters directly inspecting the internal state" do
      #   expect(custom_formatter(with_password)).to_not contain "@name:"
      #   expect(custom_formatter(with_password)).to_not contain "@password:"
      # end
    end

    context "when the attribute has been set to nil" do
      before_each do
        with_password.name = nil
        with_password.password = nil
      end

      it "is displayed as nil in #inspect (like .property)" do
        expect(with_password.inspect).to contain "@name=nil"
        expect(with_password.inspect).to contain "@password=nil"
      end

      it "is displayed as nil by pp (like .property)" do
        expect(with_password.inspect).to contain "@name=nil"
        expect(with_password.inspect).to contain "@password=nil"
      end

      # it "is reported as empty to formatters directly inspecting the internal state" do
      #   expect(custom_formatter(with_password)).to contain "@name:"
      #   expect(custom_formatter(with_password)).to contain "@password:"
      # end
    end

    context "when the attribute has a value" do
      before_each do
        with_password.name = "Skroob"
        with_password.password = "12345"
      end

      it "is hidden in #inspect" do
        expect(with_password.inspect).to contain "@name=\"Skroob\""
        expect(with_password.inspect).to contain "@password=<secret>"
      end

      it "is hidden to pp" do
        expect(with_password.inspect).to contain "@name=\"Skroob\""
        expect(with_password.inspect).to contain "@password=<secret>"
      end

      # it "is hidden from formatters directly inspecting the internal state" do
      #   expect(custom_formatter(with_password)).to contain "@name: Skroob;"
      #   expect(custom_formatter(with_password)).to contain "@password: <secret>;"
      # end
    end
  end
end
