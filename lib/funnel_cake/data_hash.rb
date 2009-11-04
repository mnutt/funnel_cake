require "fastercsv"

class FunnelCake::DataHash < ::Hash

  def to_csv(options={})
    if values.all? { |e| e.respond_to?(:to_row) }
      headers = values.first.to_row_columns(options[:format])
      header_row = FasterCSV.generate_line(headers, options)

      rows = values
      rows = rows.sort { |a,b| a[:index]<=>b[:index] } if headers.include?(:index)

      content_rows = rows.map { |e| e.to_row(headers, options[:format]) }.map do |row|
        FasterCSV.generate_line(row, options)
      end

      ([header_row] + content_rows).join
    else
      FasterCSV.generate_line(self.keys, options) + FasterCSV.generate_line(self.values, options)
    end
  end

  def to_row_columns(format = nil)
    keys
  end

  def to_row(headers, format = nil)
    headers.collect { |k| self[k] }
  end

end
