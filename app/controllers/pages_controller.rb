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

      begin
        @contract = Contract.new(start_date, end_date, salary)
        # First result table
        @periods = @contract.split_into_leave_periods    

        # Second result table
        @months = []
        if @periods.present?
          last_period_value = 0
          ten_percent_rest = 0
          dozen_rest = 0

          @periods.each_with_index do |period, index|
            @months += divide_period_by_month(
              period,
              @contract.end_date, 
              last_period_value,
              ten_percent_rest,
              dozen_rest
            )
            last_period_value = period.final_leave_value
            @months.each do |month|
              ten_percent_rest += month.payment_by_ten_percent 
              dozen_rest += month.payment_by_the_dozen_rest
            end
            # the rest of the 10% method is the value of the leave period - the sum of all 10% payments
            ten_percent_rest = period.final_leave_value - ten_percent_rest
            # the rest of the 1/12 method is the value of the leave period - the sum of all 1/12 payments
            dozen_rest = period.final_leave_value - dozen_rest
          end
        end
      rescue ArgumentError => e
        flash[:error] = e.message
        redirect_to simulator_path and return
      end
    else
      flash[:error] = "Veuillez remplir tous les champs."
      redirect_to simulator_path and return
    end
    render :simulator
  end

  def divide_period_by_month(
      period, 
      contract_end_date, 
      last_period_leave_value, 
      last_period_ten_percent_rest=0.0, 
      last_period_by_the_dozen_rest=0.0
    )
    months = []

    # If the period is less than a month, we return it as a single month
    if period.start_date.year == period.end_date.year && period.start_date.month == period.end_date.month
      months << MonthlyPayment.new(period.start_date, period.end_date, period.salary)
      return months
    end

    current_start = period.start_date

    while current_start <= period.end_date
      month_end = Date.new(current_start.year, current_start.month, -1)
      month_end = [month_end, period.end_date].min
      # if it is the end of the contract, apply all regularisations
      new_month = MonthlyPayment.new(current_start, month_end, period.salary, last_period_leave_value, last_period_ten_percent_rest)
      if month_end == contract_end_date
        new_month.payment_by_the_dozen_rest = last_period_by_the_dozen_rest
        new_month.current_period_leave_value = period.final_leave_value
        new_month.adjust_payments_end_of_contract()
      end

      months << new_month
      current_start = month_end + 1
    end

    months
  end
end