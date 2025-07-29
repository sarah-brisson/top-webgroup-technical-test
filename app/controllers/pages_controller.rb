class PagesController < ApplicationController
  def simulator
    # renders the form
  end

  def calculate
    if params[:start_date] != nil && params[:end_date] != nil && params[:salary] != nil
      begin
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        salary = params[:salary].to_f
      rescue ArgumentError => e
        flash[:error] = "Invalid date format or salary value."
        return
      end
    end
    @contract = Contract.new(start_date, end_date, salary)
    @periods = @contract.split_into_leave_periods
    puts "Contract created: #{@periods.size} periods."
    return render :calculate
  end
end