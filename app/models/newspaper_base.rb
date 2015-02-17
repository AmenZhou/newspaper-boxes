class NewspaperBase < ActiveRecord::Base
  include Geokit::Geocoders 

  validates :type, presence: true
  scope :by_city, -> (city) { where(city: city) }
  scope :by_borough, -> (borough) {where(borough_detail: borough)}
  default_scope -> {where(trash: false)}

  before_save :update_lat_lng, except: [:destroy, :recovery]

  QueensArea = {"Queens West" => ["Woodside", "Elmhurst", "Rego Park", "Forest Hills"],
                "Queens Middle" => ["Flushing"],
                "Queens East" => ["Fresh Meadows", "Bayside", "Oakland Gardens", "Douglaston", "Little Neck"]}

  ColumnName = [:delete, :edit, :sort_num, :address, :city, :state, :zip, :borough_detail, :address_remark, :created_at, :deliver_type, :iron_box, :plastic_box, :selling_box, :paper_shelf, :mon, :tue, :wed, :thu, :fri, :sat, :sun, :date_t, :remark, :building, :place_type]
  SumArray = [:iron_box, :plastic_box, :selling_box, :paper_shelf, :mon, :tue, :wed, :thu, :fri, :sat, :sun]

  scope :by_address, -> (address) { where('address LIKE ?', "%#{address}%")}

  scope :by_group, ->(group) { group(group).select("#{group}, sum(mon) as mon, sum(tue) as tue,  sum(wed) as wed, sum(thu) as thu,  sum(fri) as fri,  sum(sat) as sat, sum(sun) as sun") }

  scope :sum_of_day, -> { select("sum(mon) as mon, sum(tue) as tue,  sum(wed) as wed, sum(thu) as thu,  sum(fri) as fri,  sum(sat) as sat, sum(sun) as sun") }

  class << self

    def weekly_total_amount
      select('sum(mon) + sum(tue) + sum(wed) + sum(thu) + sum(fri) as mon').first.mon
    end

    def deliver_type
      #[[1, "Spain"], [2, "Italy"], [3, "Germany"], [4, "France"]]
      #NewspaperBoxes.pluck(:deliver_type)
      @delivery_types ||= self.pluck(:deliver_type).compact.reject(&:empty?).uniq.map{|np| [np, np]}
    end

    def zipcode_list
      @zipcode_list ||= self.pluck(:zip).uniq.compact.sort.delete_if(&:blank?)
    end

    def city_list
      @city_list ||= self.pluck(:city).uniq.compact.sort.delete_if(&:blank?)
    end

    def borough_list
      @borough_list ||= self.pluck(:borough_detail).uniq.compact.sort.delete_if(&:blank?)
    end

    def get_newspaper_bases_n_sum(trash=false)
      @newspaper_bases = NewspaperBase.unscoped.where(trash: trash, type: @class_type)
      newspaper_sum
    end

    def newspaper_sum
      @newspaper_sum = {}
      model_name::SumArray.each do |week_day|
        @newspaper_sum.send( :[]=, week_day.to_sym, @newspaper_bases.sum(week_day.to_sym))
      end
    end

    def avg_week_count
      total = NewspaperBox.all.inject(0){|sum, np| sum += np.week_count}
      (total.to_f / NewspaperBox.count).round(2)
    end

    def fix_nil
      %w(mon tue wed thu fri sat sun).each do |day|
        NewspaperBox.where("#{day} is null").update_all("#{day}= 0")
      end
    end
    #REPORT GENERATE RELATED METHODS
    def weekday_average_report
      newspapers = by_group('borough_detail')
      report_list = ReportList.new(newspapers: newspapers, group_name: 'borough_detail', days_range: :mon_2_thu)
      report_list.reports
    end

    def weekend_average_report
      newspapers = by_group('borough_detail')
      report_list = ReportList.new({newspapers: newspapers, group_name: 'borough_detail', days_range: :fri_2_sat})
      report_list.reports
    end

    def report
      newspapers = by_group('borough_detail')
      report_list = ReportList.new({newspapers: newspapers, group_name: 'borough_detail', days_range: :mon_2_sat})
      report_list.reports
    end

    def report_queens
      report_list = ReportList.new
      QueensArea.each do |key, value|
        newspaper = by_borough('Queens').by_city(value).sum_of_day.first
        report = Report.new(newspaper: newspaper, group_name: 'Queens Area', group: key + ' - ' + value.join(', '), days_range: :mon_2_sat)
        report.set_attributes
        report_list.add_to_list(report)
      end
      report_list.reports
    end

    def zipcode_report
      newspapers = by_group('zip')
      amount = weekly_total_amount
      report_list = ReportList.new({newspapers: newspapers, group_name: 'zip', days_range: :mon_2_sat, newspaper_total_amount: amount})
      ###Add last row as a sum
      report_list.generate_weekday_columns_sum
      report_list.reports
    end

    def single_day_borough_report day = :fri
      newspapers = by_group('borough_detail')
      report_list = ReportList.new({newspapers: newspapers, group_name: 'borough_detail', days_range: day})
      report_list.reports
    end

    def calc_paper_amount_by_newspaper_boxes(newspaper_boxes, group, calc_type=:amount)
      reports = []
      newspaper_boxes.each do |row|
        next if group && (row.send(group).nil? || row.send(group).blank?)
        if group
          report = Report.new(group, row.send(group))
        else
          report = Report.new
        end
        report.set_seven_weekday_and_sum(row, calc_type)
        reports << report
      end
      reports
    end

    def calc_paper_amount(group=nil, calc_type=:amount)
      if group.nil?
        rs = self.select("sum(mon) as mon, sum(tue) as tue,  sum(wed) as wed, sum(thu) as thu,  sum(fri) as fri,  sum(sat) as sat, sum(sun) as sun")
      else
        rs = self.group(group).select("#{group}, sum(mon) as mon, sum(tue) as tue,  sum(wed) as wed, sum(thu) as thu,  sum(fri) as fri,  sum(sat) as sat, sum(sun) as sun")
      end
      calc_paper_amount_by_newspaper_boxes(rs, group, calc_type)
    end

    def get_amount_by(group, condition)
      reports = calc_paper_amount(group)
      reports.select! { |r| r.send(group) == condition}
    end

    def generate_a_line(type="title", newspaper_box=nil)
      line = ""
      self::ColumnName.each do |attr|
        next if [:delete, :edit].include?(attr)
        if type == "title"
          line += attr.to_s + '|'
        else
          line += newspaper_box.send(attr).to_s + '|'
        end
      end
      line.gsub("\n", "").encode("UTF-8")
    end

    def export_data
      file_path = ""
      unless File.directory?('lib/export')
        Dir.mkdir 'lib/export'
      end
      File.open('lib/export/' + self.to_s.downcase + '_export_'+ Time.now.strftime("%d%m%Y-%H:%M") + '.csv', 'w') do |file|
        file.puts(generate_a_line("title") + "\n")

        self.all.each do |nb|
          file.puts(generate_a_line("data", nb) + "\n")
        end
        file_path = file.path
      end
      file_path
    end
  end

  #instance method
  def update_lat_lng
    #FIXME add google api key will work, otherwise will be limitation of query
    geo  = MultiGeocoder.geocode(display_address)
    self.latitude = geo.lat
    self.longitude = geo.lng
  end

  def display_address
    "#{address}, #{city}, #{state}, #{zip}"
  end

  def weekday_changed?
    %w(mon tue wed thu fri sat sun).each do |weekday|
      return true if self.send("#{weekday}_changed?")
    end
    false
  end

  def week_count
    mon + tue + wed + thu + fri + sat + sun rescue 0
  end

  def is_newspaper_box?
    true if self.deliver_type == 'Newspaper box'
  end

  def generate_location_info
    location = {}
    location['latitude'] = latitude 
    location['longitude'] = longitude
    location['paper_count'] = instance_of?(NewspaperHand)? 0 : week_count
    location['address'] = display_address
    if type == 'NewspaperHand'
      location['icon'] = 'red'
    elsif deliver_type == 'Newspaper box'
      location['icon'] = 'green'
    else
      location['icon'] = 'blue'
    end
    location
  end
end
