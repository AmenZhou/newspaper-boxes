class NewspaperBox < NewspaperBase
  ColumnName = [:delete, :edit, :sort_num, :new_box_flg, :address, :city, :state, :zip, :borough_detail, :address_remark, :created_at, :deliver_type, :iron_box, :plastic_box, :selling_box, :paper_shelf, :mon, :tue, :wed, :thu, :fri, :sat, :sun, :date_t, :remark]
  SumArray = [:iron_box, :plastic_box, :selling_box, :paper_shelf, :mon, :tue, :wed, :thu, :fri, :sat, :sun]
end
