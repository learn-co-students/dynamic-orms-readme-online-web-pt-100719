require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

  def self.table_name # Changes Song to songs
    self.to_s.downcase.pluralize
  end

  # Let's go get the column names!
  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "PRAGMA table_info('#{table_name}')" # Fills in the name of the table (i.e. songs, dogs, cats, etc.)

    table_info = DB[:conn].execute(sql)
    column_names = [] # Stores the column names

    table_info.each do |column|
      column_names << column["name"] # Collects 'just' the column name
    end

    column_names.compact # Gets rid of any 'nil' values
  end

  # Builds the attr_accessor for our class
  self.column_names.each do |col_name| # Takes our column names and iterates over each one
    attr_accessor col_name.to_sym # Converts the column name to symbol
  end

  # Our initialize method takes in a hash of name arguments
  def initialize(options={}) # Not explicitly defining the arguments
    options.each do |property, value| # Key and value
      self.send("#{property}=", value) # Sets the key to equal a value
    end
  end

  # Saves or inserts into which ever table we want
  def table_name_for_insert
    self.class.table_name
  end

  # Abstracting the column names
  # We at first DON'T insert the id column
  # Remove id from the array of column names
  def col_names_for_insert
    # Inserts all columns except for "id"
    # Joins the other columns together, separated by commas
    self.class.column_names.delete_if {|col| col == "id"}.join(",")
  end

  # Takes the values for insert
  # Stores them in the values array
  # Iterates over the values in each column
  # Shovels them in to the values array
  # Unless the value is 'nil'
  # Encapsulates the values in single quotes
  # Joins the values together using a comma
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  # Does our inserting using dynamic table and column names
  def save
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES(?)", [values_for_insert])
    id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  # Finds the record we want by name
  # Uses select query and passes in the table name using the name of instance of the class
  def self.find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", [name])
  end

end
