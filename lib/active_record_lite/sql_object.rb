require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = "#{table_name.underscore}"
  end

  def self.table_name
    @table_name
  end

  def self.all
    parse_all(DBConnection.execute("SELECT * FROM #{self.table_name}"))
  end

  def self.find(id)
    parse_all(DBConnection.execute("
          SELECT * 
            FROM #{self.table_name}
           WHERE id = ?", id))[0]
  end

  def create
    qs = (['?']*self.class.attributes.count).join(", ")
    nams, vals = self.class.attributes.join(", "), attribute_values
    query = <<-SQL
       INSERT INTO #{self.class.table_name} (#{nams})
            VALUES (#{qs})
               SQL
    DBConnection.execute(query, *vals)
    self.id = DBConnection.last_insert_row_id
  end

  def update
    qs = (['?']*self.class.attributes.count).join(", ")
    set_line = self.class.attributes.map{|attr_name| "#{attr_name} = ?"}.join(", ")
    vals = attribute_values
    query = <<-SQL
            UPDATE #{self.class.table_name}
               SET #{set_line}
             WHERE id = #{self.id}
               SQL
    DBConnection.execute(query, *vals)
  end

  def save
    self.id.nil? ? self.create : self.update
  end

  def attribute_values
    self.class.attributes.map {|attri| self.send(:"#{attri}")}
  end
end
