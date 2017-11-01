require 'active_support/core_ext/hash'

module JSON

  def self.parse_with_cast(json)
    cast_value(parse(json))
  end

  def self.cast_value(value)
    case value
      when Array
        value.map!(&method(:cast_value))
      when Hash
        value
            .with_indifferent_access
            .transform_values!(&method(:cast_value))
      when 'true'
        true
      when 'false'
        false
      when /^\//
        Pathname(value)
      when Proc.new {|value| Integer(value) rescue false}
        Integer(value)
      when Proc.new {|value| value.to_s.size > 200}
        value
      when Proc.new {|value| DateTime.to_datetime rescue false}
        value.to_datetime
      else value
    end
  end

end