
module JsonHelper

  private

  def json_parse(json)
    JSON
        .parse(json)
        .with_indifferent_access
        .tap(&method(:cast_value))
  end

  def cast_value(value)
    case value
      when 'true'
        true
      when 'false'
        false
      when String
        Integer(value) rescue value
      when Array
        value.map!(&method(:cast_value))
      when Hash
        value.transform_values!(&method(:cast_value))
      else value
    end
  end

end