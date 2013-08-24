require_relative './db_connection'

module Searchable
  def where(params)
    key_s, val_s = [], []
    params.each{|key, value| key_s << "#{key} = ?"; val_s << "#{value}"}
    key_s = key_s.join(" AND ")
    parse_all(DBConnection.execute("SELECT *
                                      FROM #{self.table_name}
                                     WHERE #{key_s};", *val_s))
  end
end