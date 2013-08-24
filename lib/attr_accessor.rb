class Object
  def self.new_attr_accessor(*syms)
    syms.each do |sym| 
      
      define_method("#{sym}=".to_sym) {|value| instance_variable_set("@#{sym}".to_sym, value)}

      define_method(sym) {instance_variable_get("@#{sym}")}
    end
  end

end
