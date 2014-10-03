module NewspaperBoxesHelper
  def chart_data reports
    output = reports.map{|rs| [rs.borough_detail, rs.sum]}
    output.unshift(['borough', 'amount'])
  end

  def chart_queens_data report
    output = report.map{|rs| [rs.area, rs.sum]}
    output.unshift(['Queens Areas', 'amount'])
  end

  def zipcode_chart_data zipcode_report
    output = zipcode_report.drop(1).map{|rs| [rs.zip.to_s, rs.mon, rs.tue, rs.wed, rs.thu, rs.fri, rs.sat, rs.sun]}
    output.unshift(['zipcode', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'])
  end

  def deliver_type newspaper_boxes
    #[[1, "Spain"], [2, "Italy"], [3, "Germany"], [4, "France"]]
    #NewspaperBoxes.pluck(:deliver_type)
    @delivery_types ||= newspaper_boxes.pluck(:deliver_type).compact.uniq.map{|np| [np, np]}
  end
  
  def td_indentation(number=1)
    number.times.map{|i| "<td>"}.join(" ")
  end
  
  def newspaper_display_by_type
    controller.controller_name.gsub('_', ' ').titleize
  end

  def table_columns(newspaper_base)
    {
       delete: -> { link_to 'x', newspaper_base, method: :delete, data: { confirm: 'Are you sure?' }, remote: true },
       sort_num: -> {best_in_place newspaper_base, :sort_num, type: :input},
       address: -> {best_in_place newspaper_base, :address, type: :input},
       city: -> {best_in_place newspaper_base, :city, type: :input},
       state: -> { best_in_place newspaper_base, :state, type: :input },
       zip: -> { best_in_place newspaper_base, :zip, type: :input },
       borough_detail: -> { best_in_place newspaper_base, :borough_detail, type: :input },
       address_remark: -> { best_in_place newspaper_base, :address_remark, type: :input},
       created_at: -> { newspaper_base.created_at.strftime('%F') },
       deliver_type: -> { best_in_place newspaper_base, :deliver_type, type: :select, collection: deliver_type(@newspaper_bases) },
       iron_box: -> { best_in_place newspaper_base, :iron_box, type: :input },
       plastic_box: -> { best_in_place newspaper_base, :plastic_box, type: :input },
       selling_box: -> { best_in_place newspaper_base, :selling_box, type: :input },
       paper_shelf: -> { best_in_place newspaper_base, :paper_shelf, type: :input },
       mon: -> { best_in_place newspaper_base, :mon, type: :input },
       tue: -> { best_in_place newspaper_base, :tue, type: :input },
       wed: -> { best_in_place newspaper_base, :wed, type: :input },
       thu: -> { best_in_place newspaper_base, :thu, type: :input },
       fri: -> { best_in_place newspaper_base, :fri, type: :input },
       sat: -> { best_in_place newspaper_base, :sat, type: :input },
       sun: -> { best_in_place newspaper_base, :sun, type: :input },
       date_t: -> { best_in_place newspaper_base, :date_t, type: :date },
       remark: -> { best_in_place newspaper_base, :remark, type: :textarea },
       building: -> { best_in_place newspaper_base, :building, type: :input },
       place_type: -> { best_in_place newspaper_base, :place_type, type: :input },
    }
  end

  def newspaper_form_items(f)
    {
      address: -> { f.text_field :address },
      city: -> { f.text_field :city },
      state: -> { f.text_field :state },
      zip: -> { f.number_field :zip },
      borough_detail: -> { f.text_field :borough_detail },
      address_remark: -> { f.text_area :address_remark },
      date_t: -> { f.datetime_select :date_t },
      deliver_type: -> { f.text_field :deliver_type },
      iron_box: -> { f.text_field :iron_box },
      plastic_box: -> { f.text_field :plastic_box },
      selling_box: -> { f.text_field :selling_box },
      paper_shelf: -> { f.text_field :paper_shelf },
      mon: -> { f.number_field :mon },
      tue: -> { f.number_field :tue },
      wed: -> { f.number_field :wed },
      thu: -> { f.number_field :thu },
      fri: -> { f.number_field :fri },
      sat: -> { f.number_field :sat },
      sun: -> { f.number_field :sun },
      remark: -> { f.text_area :remark },
      building: -> { f.text_field :building},
      place_type: -> { f.text_field :place_type },
      sort_num: -> { f.number_field :sort_num }
    }
  end

  def newspaper_new_path
    "#{controller.controller_name}/new"
  end

  def newspaper_index_path
    "#{controller.controller_name}"
  end

  def newspaper_export_path
    "#{controller.controller_name}/export_data"
  end

  def newspaper_recovery_path(newspaper_base)
    "#{controller.controller_name}/" + newspaper_base.id.to_s + "/recovery"
  end
end
