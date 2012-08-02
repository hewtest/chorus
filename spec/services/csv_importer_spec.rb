require 'tempfile'
require 'spec_helper'

describe CsvImporter, :database_integration => true do
  describe "actually performing the import" do

    before do
      refresh_chorus
      any_instance_of(CsvImporter) { |importer| stub(importer).destination_dataset { datasets(:bobs_table) } }
    end

    let(:schema) { GpdbSchema.find_by_name('test_schema') }
    let(:user) { account.owner }
    let(:account) { real_gpdb_account }
    let(:workspace) { Workspace.create({:sandbox => schema, :owner => user, :name => "TestCsvWorkspace"}, :without_protection => true) }

    let(:csv_file) { }
    let(:csv_file_params) {

    }

    it "imports a basic csv file as a new table" do
      csv_file = create_csv_file
      CsvImporter.import_file(csv_file.id)

      schema.with_gpdb_connection(account) do |connection|
        result = connection.exec_query("select * from new_table_from_csv order by ID asc;")
        result[0].should == {"id" => 1, "name" => "foo"}
        result[1].should == {"id" => 2, "name" => "bar"}
        result[2].should == {"id" => 3, "name" => "baz"}
      end
    end

    it "import a basic csv file into an existing table" do
      csv_file = create_csv_file(:new_table => true)
      CsvImporter.import_file(csv_file.id)

      csv_file = create_csv_file(:new_table => false)
      CsvImporter.import_file(csv_file.id)

      schema.with_gpdb_connection(account) do |connection|
        result = connection.exec_query("select count(*) from new_table_from_csv;")
        result[0]["count"].should == 6
      end
    end

    it "should truncate the existing table when truncate=true"

    it "import a csv file into an existing table with different column order" do
      f1 = Tempfile.new("test_csv_2")
      f1.puts "1,foo\n2,bar\n3,baz\n"
      f1.close

      first_csv_file = CsvFile.new(:contents => f1,
                             :column_names => [:id, :name],
                             :types => [:integer, :varchar],
                             :delimiter => ',',
                             :file_contains_header => false,
                             :new_table => true,
                             :to_table => "new_table_from_csv_2")
      first_csv_file.user = user
      first_csv_file.workspace = workspace
      first_csv_file.save!

      CsvImporter.import_file(first_csv_file.id)

      f2 = Tempfile.new("test_csv_2")
      f2.puts "dig,4\ndug,5\ndag,6\n"
      f2.close


      second_csv_file = CsvFile.new(:contents => f2,
                             :column_names => [:name, :id],
                             :types => [:varchar, :integer],
                             :delimiter => ',',
                             :file_contains_header => false,
                             :new_table => false,
                             :to_table => "new_table_from_csv_2")
      second_csv_file.user = user
      second_csv_file.workspace = workspace
      second_csv_file.save!

      CsvImporter.import_file(second_csv_file.id)

      schema.with_gpdb_connection(account) do |connection|
        result = connection.exec_query("select * from new_table_from_csv_2 order by id asc;")
        result[0]["id"].should == 1
        result[0]["name"].should == "foo"
        result[1]["id"].should == 2
        result[1]["name"].should == "bar"
        result[2]["id"].should == 3
        result[2]["name"].should == "baz"
        result[3]["id"].should == 4
        result[3]["name"].should == "dig"
        result[4]["id"].should == 5
        result[4]["name"].should == "dug"
        result[5]["id"].should == 6
        result[5]["name"].should == "dag"
      end
    end

    it "import a csv file that has fewer columns than destination table" do
      tablename = "test_import_existing_2"
      f1 = Tempfile.new("test_csv_2")
      f1.puts "1,a,snickers\n2,b,kitkat\n"
      f1.close

      first_csv_file = CsvFile.new(:contents => f1,
                                   :column_names => [:id, :name, :candy_type],
                                   :types => [:integer, :varchar, :varchar],
                                   :delimiter => ',',
                                   :file_contains_header => false,
                                   :new_table => true,
                                   :to_table => tablename)
      first_csv_file.user = user
      first_csv_file.workspace = workspace
      first_csv_file.save!

      CsvImporter.import_file(first_csv_file.id)

      f2 = Tempfile.new("test_csv_2")
      f2.puts "marsbar,3\nhersheys,4\n"
      f2.close


      second_csv_file = CsvFile.new(:contents => f2,
                                    :column_names => [:candy_type, :id],
                                    :types => [:varchar, :integer],
                                    :delimiter => ',',
                                    :file_contains_header => false,
                                    :new_table => false,
                                    :to_table => tablename)
      second_csv_file.user = user
      second_csv_file.workspace = workspace
      second_csv_file.save!

      CsvImporter.import_file(second_csv_file.id)

      schema.with_gpdb_connection(account) do |connection|
        result = connection.exec_query("select * from #{tablename} order by id asc;")
        result[0]["id"].should == 1
        result[0]["name"].should == "a"
        result[0]["candy_type"].should == "snickers"
        result[1]["id"].should == 2
        result[1]["name"].should == "b"
        result[1]["candy_type"].should == "kitkat"
        result[2]["id"].should == 3
        result[2]["name"].should == nil
        result[2]["candy_type"].should == "marsbar"
        result[3]["id"].should == 4
        result[3]["name"].should == nil
        result[3]["candy_type"].should == "hersheys"
      end



    end

    it "imports a file with different column names, header rows and a different delimiter" do
      f = Tempfile.new("test_csv")
      f.puts "ignore\tme\n1\tfoo\n2\tbar\n3\tbaz\n"
      f.close

      csv_file = CsvFile.create(:contents => f,
                                :column_names => [:id, :dog],
                                :types => [:integer, :varchar],
                                :delimiter => "\t",
                                :file_contains_header => true,
                                :new_table => true,
                                :to_table => "another_new_table_from_csv")
      csv_file.user = user
      csv_file.workspace = workspace
      csv_file.save!

      CsvImporter.import_file(csv_file.id)

      schema.with_gpdb_connection(account) do |connection|
        result = connection.exec_query("select * from another_new_table_from_csv order by ID asc;")
        result[0].should == {"id" => 1, "dog" => "foo"}
        result[1].should == {"id" => 2, "dog" => "bar"}
        result[2].should == {"id" => 3, "dog" => "baz"}
      end
    end
  end

  describe "without connecting to GPDB" do
    let(:csv_file) { CsvFile.first }
    let(:user) { csv_file.user }
    let(:dataset) { datasets(:bobs_table) }
    let(:instance_account) { csv_file.workspace.sandbox.instance.account_for_user!(csv_file.user) }

    describe "destination_dataset" do
      before do
        mock(Dataset).refresh(instance_account, csv_file.workspace.sandbox)
      end

      it "performs a refresh and returns the dataset matching the import table name" do
        importer = CsvImporter.new(csv_file.id)
        importer.destination_dataset.name.should == csv_file.to_table
      end
    end

    describe "when the import is successful" do
      before do
        any_instance_of(GpdbSchema) { |schema| stub(schema).with_gpdb_connection }
        any_instance_of(CsvImporter) { |importer| stub(importer).destination_dataset { dataset } }
        CsvImporter.import_file(csv_file.id)
      end

      it "makes a IMPORT_SUCCESS event" do
        event = Events::IMPORT_SUCCESS.first
        event.actor.should == user
        event.dataset.should == dataset
        event.workspace.should == csv_file.workspace
        event.file_name.should == csv_file.contents_file_name
        event.import_type.should == 'file'
      end

      it "deletes the file" do
        expect { CsvFile.find(csv_file.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "when the import fails" do
      before do
        @error = 'ActiveRecord::JDBCError: ERROR: relation "test" already exists: CREATE TABLE test(a float, b float, c float);'
        exception = ActiveRecord::StatementInvalid.new(@error)
        any_instance_of(GpdbSchema) { |schema| stub(schema).with_gpdb_connection { raise exception } }
        CsvImporter.import_file(csv_file.id)
      end

      it "makes a IMPORT_FAILED event" do
        event = Events::IMPORT_FAILED.first
        event.actor.should == user
        event.destination_table.should == dataset.name
        event.workspace.should == csv_file.workspace
        event.file_name.should == csv_file.contents_file_name
        event.import_type.should == 'file'
        event.error_message.should == @error
      end

      it "deletes the file" do
        expect { CsvFile.find(csv_file.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  def create_csv_file(options = {})
    f = Tempfile.new("test_csv_2")
    f.puts "1,foo\n2,bar\n3,baz\n"
    f.close
    csv_file = CsvFile.new(:contents => f,
                           :column_names => [:id, :name],
                           :types => [:integer, :varchar],
                           :delimiter => ',',
                           :file_contains_header => false,
                           :new_table => (options[:new_table].nil? ? true : options[:new_table]),
                           :to_table => "new_table_from_csv")
    csv_file.user = user
    csv_file.workspace = workspace
    csv_file.save!
    csv_file
  end
end