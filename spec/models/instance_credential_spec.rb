require 'spec_helper'

describe InstanceAccount do
  it "should allow mass-assignment of username and password" do
    InstanceAccount.new(:db_username => 'aname').db_username.should == 'aname'
    InstanceAccount.new(:db_password => 'apass').db_password.should == 'apass'
  end

  describe "associations" do
    it { should belong_to :owner }
    it { should validate_presence_of :owner}

    it { should belong_to :instance }
    it { should validate_presence_of :instance}
  end
end
