class NewspaperBox < ActiveRecord::Base
  include Geokit::Geocoders
  has_many :box_records
  # attr_accessible :address, :city, :state
  scope :by_city, -> (city) { where(city: city) }
  scope :by_borough, -> (borough) {where(borough_detail: borough)}
  default_scope -> {where(trash: false)}
  
  before_save do
    geo  = MultiGeocoder.geocode(display_address)
    self.latitude = geo.lat
    self.longitude = geo.lng
  end
  
  after_save :process_history

  QueensArea = {"Queens1" => ["Woodside", "Elmhurst", "Rego Park", "Forest Hills"],
                "Queens2" => ["Flushing"],
                "Queens3" => ["Fresh Meadows", "Bayside", "Oakland Gardens", "Douglaston", "Little Neck"]}


  ExportFilePath = "db/newspaper_export.csv"
    
  class << self
    def zipcode_list
      @zipcode_list ||= self.pluck(:zip).uniq.compact.sort
    end

    def city_list
      @city_list ||= self.pluck(:city).uniq.compact.sort
    end

    def borough_list
      @borough_list ||= self.pluck(:borough_detail).uniq.compact.sort
    end
  end

  def self.upload(file) 
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      newspaper_box = find_by_id(row["id"]) || new
      newspaper_box.attributes = row.to_hash
      newspaper_box.save!
    end
  end

  def self.avg_week_count
    total = NewspaperBox.all.inject(0){|sum, np| sum += np.week_count}
    (total.to_f / NewspaperBox.count).round(2)
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    when ".xls" then Roo::Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Roo::Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def self.fix_nil
    %w(mon tue wed thu fri sat sun).each do |day|
      NewspaperBox.where("#{day} is null").update_all("#{day}= 0")
    end
  end
 
      def weekday_changed?
        %w(mon tue wed thu fri sat sun).each do |weekday|
          return true if self.send("#{weekday}_changed?")
        end
        false
      end

      def process_history
        if new_record? or weekday_changed?
          History.generate_a_record(self)
        end
      end
      
  def display_address
    "#{address}, #{city}, #{state}, #{zip}"
  end

  def update_lat_lng
    #FIXME add google api key will work, otherwise will be limitation of query
    #geo = Geokit::Geocoders::GoogleGeocoder.geocode(display_address)
    geo  = MultiGeocoder.geocode(display_address)
    update_attributes(latitude: geo.lat, longitude: geo.lng)
  end

  def self.report
    calc_paper_amount(:borough_detail)
  end

  def self.report_queens
    newspaper_boxes = NewspaperBox.where(borough_detail: 'Queens')
    report = []
    NewspaperBox::QueensArea.each do |k, v|
      hash = {}
      rs = newspaper_boxes.where(city: v).select("sum(mon) as mon, sum(tue) as tue,  sum(wed) as wed, sum(thu) as thu,  sum(fri) as fri,  sum(sat) as sat, sum(sun) as sun")
      hash[:area] = k + " (" + v.join(" ") + ")"
      hash[:amount] = rs.first.week_count
      report << hash
    end
    report
  end

  def week_count
    mon + tue + wed + thu + fri + sat + sun rescue 0
  end

  def self.zipcode_report
    report = calc_paper_amount(:zip)
    ###Add last row as a sum
    hash = {}
    %w(mon tue wed thu fri sat sun sum).each do |week_day|
      hash[week_day.to_sym] = report.inject(0){|sum, h| sum += h[week_day.to_sym]}
    end
    report << hash
    report
  end
      
      def self.calc_paper_amount_by_newspaper_boxes(newspaper_boxes, group)
        report = []
        newspaper_boxes.each do |row|
          hash = {}
          hash[group] = row.send(group) if group
          %w(mon tue wed thu fri sat sun).each do |week_day|
            hash.send(:[]=, week_day.to_sym, row.send(week_day))
          end
          hash[:sum] = row.week_count
          report << hash
        end
        report
      end

      def self.calc_paper_amount(group=nil)
        if group.nil?
          rs = NewspaperBox.select("sum(mon) as mon, sum(tue) as tue,  sum(wed) as wed, sum(thu) as thu,  sum(fri) as fri,  sum(sat) as sat, sum(sun) as sun")
        else
          rs = NewspaperBox.group(group).select("#{group}, sum(mon) as mon, sum(tue) as tue,  sum(wed) as wed, sum(thu) as thu,  sum(fri) as fri,  sum(sat) as sat, sum(sun) as sun")
        end
        calc_paper_amount_by_newspaper_boxes(rs, group)
      end
      
  def is_newspaper_box?
    true if self.deliver_type == 'Newspaper box'
  end

  def self.generate_a_line(type="title", newspaper_box=nil)
    line = ""
    %w(sort_num address city state zip borough_detail address_remark date_t deliver_type remark iron_box plastic_box selling_box paper_shelf mon tue wed thu fri sat sun latitude longitude created_at).each do |attr|
      if type == "title"
        line += attr + '|'
      else
        line += newspaper_box.send(attr).to_s + '|'
      end
    end
    line
  end

  def self.export_data
    #DateTime.now.strftime('%D')
    file = File.new(NewspaperBox::ExportFilePath, 'w')
    
    file.puts(generate_a_line("title") + "\n")
    
    NewspaperBox.all.each do |nb|
      file.puts(generate_a_line("data", nb) + "\n")
    end
    file.close()
  end
end
