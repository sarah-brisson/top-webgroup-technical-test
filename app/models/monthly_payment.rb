
require 'date'
require_relative '../../lib/utils'

class MonthlyPayment
  attr_reader :perceived_salary, :payment_in_june, :payment_by_the_dozen, :payment_by_ten_percent
  attr_accessor :start_date, :end_date, :salary, :last_period_leave_value, :payment_by_the_dozen_rest, :payment_by_ten_percent_rest, :current_period_leave_value

  def initialize(
      start_date, 
      end_date, 
      salary, 
      last_period_leave_value=0.0, 
      payment_by_ten_percent_rest=0.0
    )
    unless start_date < end_date
      raise ArgumentError, "Start date should be before end date."
    end
    unless start_date.month == end_date.month && start_date.year == end_date.year
      raise ArgumentError, "Start date and end date should be the same month."
    end

    @start_date = start_date
    @end_date = end_date
    @salary = salary.to_f 
    @last_period_leave_value = last_period_leave_value.to_f
    @payment_by_ten_percent_rest = payment_by_ten_percent_rest.to_f.round(2)
    @payment_by_the_dozen_rest = 0.0
    @payment_by_ten_percent = 0.0
    @current_period_leave_value = 0.0

    calculate_perceived_salary()
    set_payment_in_june()
    set_payment_by_the_dozen()
    set_payment_by_ten_percent() 
  end

  public def calculate_perceived_salary
    if Utils.is_full_month(@start_date, @end_date)
      @perceived_salary = @salary
    else
      # prorata salary for the month
      @perceived_salary = @salary * Utils.calculate_nb_days_prorata(@start_date, @end_date)
    end
    @perceived_salary
  end

  def set_payment_in_june
    if @start_date.month == 6
      @payment_in_june = @last_period_leave_value.round(2)
    else
      @payment_in_june = 0.0
    end
  end

  def set_payment_by_the_dozen
    if @last_period_leave_value != 0
      @payment_by_the_dozen = (@last_period_leave_value / 12).round(2)
    else
      @payment_by_the_dozen = 0.0
    end
  end

  def set_payment_by_ten_percent
    @payment_by_ten_percent = (@perceived_salary * 0.1).round(2)
    # If it's June, we need to add the rest of the last period
    if @start_date.month == 6
      @payment_by_ten_percent += @payment_by_ten_percent_rest
    end
  end

  def adjust_payments_end_of_contract
    # Payment in June
    # If it's june we need to pay the last period leave value + this period's value
    @payment_in_june = (@payment_in_june + @current_period_leave_value).round(2)

    # Payment by the dozen
    # We need to pay the rest that is due + the accumulation from the current period
    @payment_by_the_dozen = (@payment_by_the_dozen + @payment_by_the_dozen_rest + @current_period_leave_value).round(2)

    # Payment by ten percent
    # We need only need to pay the rest that is due
    @payment_by_ten_percent = (@payment_by_ten_percent + @payment_by_ten_percent_rest).round(2)
  end
end