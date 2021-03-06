class NewspaperBasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_newspaper_base, only: [:update, :edit]
  before_action :set_newspaper_base_for_trash_bin, only: [:recovery, :destroy]
  before_action :is_admin?, except: [:map]
  helper_method :model_name

  def index
    @newspaper_bases = model_name_branch.order("sort_num")
    filter_newspaper_base
    @newspaper_amount = @newspaper_bases.count
    @newspaper_bases = @newspaper_bases.page(params[:page]).per(10)
    newspaper_sum
  end

  def new
    @newspaper_base = model_name.new
  end

  def create
    @newspaper_base = model_name.new(newspaper_params.merge(epoch_branch_id: current_user.epoch_branch_id))
    if @newspaper_base.save
      redirect_to action: 'index', notice: 'Update Newspaper Successfully!'
    else
      #TODO return error message here
      render 'new'
    end
  end
 
  def update
    respond_to do |format|
      if @newspaper_base.update(newspaper_params)
        format.html { redirect_to action: :index }
        format.json { head :no_content }
      else
        format.html { render :edit }
        format.json { render json: @newspaper_base.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit

  end

  def recovery
    @newspaper_base.trash = false
    @nb_id = @newspaper_base.id
    if @newspaper_base.save
     # flash[:success] = "Recovery Successfully"
      @result = true
    else
     # flash[:error] = "Recovery Failed"
      @result = false
    end
    get_newspaper_bases_n_sum(true)
    @newspaper_amount = model_name.unscoped.where(trash: true).count
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @nb_id = @newspaper_base.id
    if @newspaper_base.trash
      @newspaper_base.destroy
      get_newspaper_bases_n_sum(true)
      @newspaper_amount = model_name.unscoped.where(trash: true).count
    else
      @newspaper_base.update(trash: true)
      get_newspaper_bases_n_sum(false)
      @newspaper_amount = model_name.count
    end
    respond_to do |format|
      format.js
      format.json { head :no_content }
    end
  end


  def map
    @citys = model_name_branch.pluck(:borough_detail).compact.uniq.delete_if{|x| x.blank?}
    @selected_city = params[:city]
    boxes = params[:city].present? ? model_name_branch.by_borough(params[:city]) : model_name_branch
    boxes = boxes.by_address(params[:address]) if params[:address].present?

    @locations = boxes.map do |np|
      np.generate_location_info
    end
    respond_to do |format|
        format.html {  }
        format.json { render json: @locations.to_json  }
      end
  end

  def export_data
    file_path = model_name.export_data(current_user.epoch_branch_id)
    send_file(file_path)
  end

  private

  def model_name_branch
    model_name.by_epoch_branch_id(current_user.epoch_branch_id)
  end

  def model_name
    controller_name.classify.gsub('Basis', 'Base').constantize
  end

  def get_newspaper_bases_n_sum(trash=false)
    @newspaper_bases = model_name.unscoped.where(trash: trash)
    newspaper_sum
  end
  
  def newspaper_sum
    @newspaper_sum = {}
    model_name::SumArray.each do |week_day|
      @newspaper_sum.send( :[]=, week_day.to_sym, @newspaper_bases.sum(week_day.to_sym))
    end
  end

  def filter_newspaper_base
    if params['zip_code'].present?
      @selected_zip_code = params['zip_code']
      @newspaper_bases = @newspaper_bases.where(zip: @selected_zip_code)
    end
    if params['city'].present?
      @selected_city = params['city']
      @newspaper_bases = @newspaper_bases.where(city: @selected_city)
    end

    if params['borough'].present?
      @selected_borough = params['borough']
      @newspaper_bases = @newspaper_bases.where(borough_detail: @selected_borough)
    end

    if params['trash'].present?
      @selected_trash = params['trash']
      @newspaper_bases = @newspaper_bases.unscoped.where(trash: true)
    end

    if params['address'].present?
      @selected_address = params['address']
      @newspaper_bases = @newspaper_bases.by_address(@selected_address)
    end
  end
  
  
  def set_newspaper_base_for_trash_bin
    @newspaper_base = model_name.unscoped.find(params[:id])
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_newspaper_base
    @newspaper_base = model_name.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def newspaper_params
    params.require(:newspaper_base).permit(:address, :city, :state, :zip, :borough_detail, :address_remark, :date_t, :deliver_type, :iron_box, :plastic_box, :selling_box, :paper_shelf, :remark, :mon, :tue, :wed, :thu, :fri, :sat, :sun, :sort_num, :building, :place_type)
  end

  def is_admin?
    redirect_to root_path  unless current_user.is_admin?
  end
end
