require "./spec_helper.cr"
Session.config.secret = "my_super_secret"
describe "Session::FileSystemEngine" do
  describe "options" do
    describe ":sessions_dir" do
      it "raises an ArgumentError if option not passed" do
        expect_raises(ArgumentError) do
          Session::FileSystemEngine.new({:no => "option"})
        end
      end

      it "raises an ArgumentError if the directory does not exist" do
        expect_raises(ArgumentError) do
          Session::FileSystemEngine.new({:sessions_dir => "foobar"})
        end
      end
    end
  end

  describe ".int" do
    it "can save a value" do
      session = Session.new(create_context("foo"))
      session.int("bar", 12)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context("foo"))
      session.int("bar", 12)
      session.int("bar").should eq 12
    end
  end

  describe ".bool" do
    it "can save a value" do
      session = Session.new(create_context("foo"))
      session.bool("bar", true)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context("foo"))
      session.bool("bar", true)
      session.bool("bar").should eq true
    end
  end

  describe ".float" do
    it "can save a value" do
      session = Session.new(create_context("foo"))
      session.float("bar", 3.00)
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context("foo"))
      session.float("bar", 3.00)
      session.float("bar").should eq 3.00
    end
  end

  describe ".string" do
    it "can save a value" do
      session = Session.new(create_context("foo"))
      session.string("bar", "kemal")
    end

    it "can retrieve a saved value" do
      session = Session.new(create_context("foo"))
      session.string("bar", "kemal")
      session.string("bar").should eq "kemal"
    end
  end
end
