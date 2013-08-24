class MassObject
  def self.set_attrs(*attributes)
    @attributes = attributes
    attributes.each{|attribute| self.send(:attr_accessor, attribute)}
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.map{|element| self.new(element)}
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.attributes.include?(attr_name.to_sym)
        self.send(:instance_variable_set, "@#{attr_name}", value)
      else
        raise StandardError.new "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end