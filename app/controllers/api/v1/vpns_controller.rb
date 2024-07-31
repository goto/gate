class ::Api::V1::VpnsController < ::Api::V1::BaseController
  before_action :set_vpn, only: [:assign_group]

  def index
    vpns = Vpn.order(:id).page(params[:page]).per(params[:per_page])
    vpns = vpns.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
    render json: vpns, status: :ok
  end

  def associated_groups
    vpn = Vpn.find_by_id(params[:id])
    return head :not_found unless vpn.present?

    groups = vpn.groups
    groups = groups.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
    render json: groups, status: :ok
  end

  def create
    if current_user.admin?
      @vpn = Vpn.new(vpn_params)
      @vpn.uuid = SecureRandom.uuid
      if @vpn.save
        render json: {
          id: @vpn.id,
          name: @vpn.name,
          host_name: @vpn.host_name,
          ip_address: @vpn.ip_address,
        }, status: :ok
      else
        render json: { status: 'error' }, status: :unprocessable_entity
      end
    end
  end

  def assign_group
    if current_user.admin?
      @vpn.groups.delete_all
      @vpn.groups << Group.where(id: params[:group_id]).first
      render json: { status: 'group assigned' }, status: :ok
    end
  end

  private

  def set_vpn
    @vpn = Vpn.find(params[:id])
  end

  def vpn_params
    params.require(:vpn).permit(:name, :host_name, :ip_address)
  end
end
