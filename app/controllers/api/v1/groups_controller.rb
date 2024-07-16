class ::Api::V1::GroupsController < ::Api::V1::BaseController
  def create
    if current_user.admin?
      @group = Group.new(group_params)
      if @group.save
        render json: {
          id: @group.id,
          name: @group.name,
        }, status: :ok
      else
        is_taken = @group.errors.details[:name].select { |x| x[:error] == :taken }

        if !is_taken.blank?
          existing_group = Group.find_by(name: @group.name)
          render json: {
            status: 'group already exist',
            id: existing_group.id,
            name: existing_group.name,
          }, status: :unprocessable_entity
        else
          render json: {
            status: 'error',
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def add_user
    @group = Group.find_by(id: params[:id])
    return head :not_found unless @group.present?

    return raise_unauthorized unless current_user.admin? || @group.admin?(current_user)

    user = User.find_by(id: params[:user_id])
    return head :unprocessable_entity unless user.present?

    expiration_date = params[:expiration_date]
    @group.add_user_with_expiration(params[:user_id], expiration_date)
    head :no_content
  end

  def remove_user
    @group = Group.find_by(id: params[:id])
    return head :not_found unless @group.present?
    
    return raise_unauthorized unless current_user.admin? || @group.admin?(current_user)
    
    user = User.find_by(id: params[:user_id])
    return head :unprocessable_entity unless user.present?
    
    @group.remove_user(params[:user_id])
    head :no_content
  end

  def get_group_member
    @group = Group.find_by(id: params[:id])
    return head :not_found unless @group.present?
  
    user = User.find_by(id: params[:user_id])
    if user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end
  
    is_member = @group.users.exists?(user.id)
    if is_member
      render json: user.as_json(only: [:id, :email, :created_at, :updated_at, :uid, :name, :active]), status: :ok
    else
      render json: { error: "User not a member of the group" }, status: :not_found
    end
  end

  private

  def group_params
    params.require(:group).permit(:name)
  end
end
