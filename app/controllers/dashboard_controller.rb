before_action :authenticate_user!

class DashboardController < ApplicationController
  def show
    @user = current_user
  end
end
