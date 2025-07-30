class PagesController < ApplicationController
  def simulator
    # renders the form
  end

  def calculate
    if params[:start_date].present? && params[:end_date].present? && params[:salary].present?
      begin
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        salary = params[:salary].to_f
      rescue ArgumentError
        flash[:error] = "Format invalide pour la date ou le salaire."
        redirect_to simulator_path and return
      end

      @contract = Contract.new(start_date, end_date, salary)
      @periods = @contract.split_into_leave_periods
    else
      flash[:error] = "Veuillez remplir tous les champs."
      redirect_to simulator_path and return
    end
    render :simulator
  end
end