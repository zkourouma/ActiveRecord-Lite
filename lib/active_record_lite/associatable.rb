require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_accessor :other_class, :primary_key, :foreign_key, :other_table_name

  def other_class
    @other_class
  end

  def other_table
    @other_table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
      other_class_name = params[:class_name] || name.to_s.singularize
      @primary_key = params[:primary_key] || "id"
      @foreign_key = params[:foreign_key] || name.to_s + "_id"
      
      @other_class = other_class_name.camelize.constantize
      @other_table_name = other_class.table_name
  end

  def type
    self.class
  end
end

class HasManyAssocParams < AssocParams
  attr_accessor :self_class
  
  def initialize(name, params, self_class)
      other_class_name = params[:class_name] || name.to_s.singularize
      @primary_key = params[:primary_key] || "id"
      @foreign_key = params[:foreign_key] || self_class.to_s.downcase + "_id"
      
      @other_class = other_class_name.camelize.constantize
      @other_table_name = other_class.table_name
      @self_class = self_class
  end

  def type
    self.class
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
    @assoc_params
  end

  def belongs_to(name, params = {})
    define_method(name) do 
      aps = BelongsToAssocParams.new(name, params)
      
      self.class.assoc_params[name] = aps

      query = <<-SQL
              SELECT *
                FROM #{aps.other_table_name}
               WHERE #{aps.primary_key} = ?
                 SQL
      aps.other_class.parse_all(DBConnection.execute(query, 
                            self.send(:"#{aps.foreign_key}")))
    end
  end

  def has_many(name, params = {})
    define_method(name) do 
      aps = HasManyAssocParams.new(name, params, self.class)
      self.class.assoc_params[name] = aps

      query = <<-SQL
              SELECT *
                FROM #{aps.other_table_name}
               WHERE #{aps.foreign_key} = ?
                 SQL
      aps.other_class.parse_all(DBConnection.execute(query, 
                            self.send(:"#{aps.primary_key}")))
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      aps1 = self.class.assoc_params[assoc1]
      aps2 = aps1.other_class.assoc_params[assoc2]      
      p_key = self.send(aps1.foreign_key)

      query = <<-SQL
              SELECT #{aps2.other_table_name}.*
                FROM #{aps2.other_table_name}
                JOIN #{aps1.other_table_name}
                  ON #{aps2.other_table_name}.#{aps1.primary_key} = #{aps1.other_table_name}.#{aps2.foreign_key}
               WHERE #{aps1.other_table_name}.#{aps1.primary_key} = ?
                 SQL

      aps2.other_class.parse_all(DBConnection.execute(query, p_key))
    end
  end
end
