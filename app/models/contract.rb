require 'date'
require_relative '../../lib/utils'

class Contract
  attr_accessor :start_date, :end_date, :salary, :periods

  def initialize(start_date, end_date, salary, periods=[])
    unless start_date.is_a?(Date) && end_date.is_a?(Date)
      raise ArgumentError, "Start date and end date must be Date objects."
    end
    unless start_date < end_date
      raise ArgumentError, "Start date should be before end date."
    end
    unless salary.is_a?(Numeric)
      raise ArgumentError, "Salary must be a numeric value."
    end

    @start_date = start_date
    @end_date = end_date
    @salary = salary.to_f # Ensure salary is a Float
  end

  def split_into_leave_periods
    periods = []
    current_start = @start_date

    while current_start <= @end_date
      # Determine the end of the current leave period
      # The leave period is between June 1 and May 31 of the next year.
      if current_start.month < 6
        period_end = Date.new(current_start.year, 5, 31)
      else
        period_end = Date.new(current_start.year + 1, 5, 31)
      end
      # Don't go past the contract's end date
      period_end = [period_end, @end_date].min

      periods << LeavePeriod.new(current_start, period_end, @salary, periods.size)
      current_start = period_end + 1
    end

    @periods = periods
    @periods.each_with_index do |period, index|
      period.parent_periods = @periods
      if index > 0
        period.payment_by_ten_percent_rest = @periods[index-1].final_leave_value
        period.payment_by_the_dozen_rest = @periods[index-1].final_leave_value
      end
    end
  end
end






class LeavePeriod < Contract
  attr_accessor :nb_months, :nb_leave_days
  attr_reader :maintain_salary_leave_value, :ten_percent_leave_value, :final_leave_value
  attr_accessor :parent_periods, :payment_by_ten_percent_rest, :payment_by_the_dozen_rest

  def initialize(start_date, end_date, salary, index=0)
    super(start_date, end_date, salary)

    if start_date.month < 6 
      max_end_date = Date.new(start_date.year, 5, 31)
      unless start_date.month < 6 && end_date <= max_end_date
        raise ArgumentError, "The period must be between May 31 and June 1 of the next year."
      end

    else
      max_end_date = Date.new(start_date.year + 1, 5, 31)
      unless start_date.month >= 6 && end_date <= max_end_date
        raise ArgumentError, "The period must be between May 31 and June 1 of the next year."
      end
    end

    @index = index
    calculate_nb_months()
    calculate_nb_leave_days()
    calculate_maintain_salary_leave_value()
    calculate_ten_percent_leave_value()
    set_final_leave_value()
    @payment_by_ten_percent_rest = 0.0
    @payment_by_the_dozen_rest = 0.0
  end

  private def calculate_nb_months
    # Contract is less than a month
    if @start_date.year == @end_date.year && @start_date.month == @end_date.month
      @nb_months = Utils.calculate_nb_days_prorata(@start_date, @end_date)
      return
    end

    # Count months between start_date and end_date
    @nb_months = 0
    current = Date.new(@start_date.year, @start_date.month, 1)
    month_end = Date.new(@start_date.year, @start_date.month, -1)
    
    # prorata applied if the month is not complete
    if @start_date.day != 1
      @nb_months += Utils.calculate_nb_days_prorata(@start_date, month_end)
      current = current.next_month
    end
    
    while current < @end_date
      if Utils.is_full_month(current, month_end)
        @nb_months += 1
      end
      current = current.next_month
      month_end = Date.new(current.year, current.month, -1)
    end

    # prorata applied if the month is not complete
    if @end_date.day != Date.new(current.year, current.month, -1).day
      @nb_months += Utils.calculate_nb_days_prorata(current, month_end)
      current = Date.new(current.year, current.month, 1)
    end

    @nb_months
  end

  private def calculate_nb_leave_days
    if @nb_months > 0
      @nb_leave_days = (@nb_months*2.5).round(3)
    else
      @nb_leave_days = 0
    end
    @nb_leave_days
  end

  private def calculate_maintain_salary_leave_value
    if @nb_leave_days > 0
      @maintain_salary_leave_value = ((@salary / 22) * @nb_leave_days).round(2)
    else
      @maintain_salary_leave_value = 0.0
    end
    @maintain_salary_leave_value
  end

  private def calculate_ten_percent_leave_value
    if @nb_leave_days > 0
      # 10% of the salary for the entire period
      @ten_percent_leave_value = (@salary * @nb_months * 0.1).round(2)
    else
      @ten_percent_leave_value = 0.0
    end
    @ten_percent_leave_value
  end

  private def set_final_leave_value
    if @maintain_salary_leave_value > @ten_percent_leave_value
      @final_leave_value = @maintain_salary_leave_value
    else
      @final_leave_value = @ten_percent_leave_value
    end
    @final_leave_value
  end

  def get_last_period_leave_value
    if @index > 0 && parent_periods && parent_periods[@index-1]
      previous_period = parent_periods[@index-1]
      previous_period.final_leave_value
    else
      0.0
    end
  end

  protected def get_last_period_ten_percent_rest
    if @index > 0 && parent_periods && parent_periods[@index-1]
      previous_period = parent_periods[@index-1]
      previous_period.payment_by_ten_percent_rest
    else
      0.0
    end
  end

  # we calculate how much of the final value is left to be paid by the ten percent method
  protected def deduct_payment_from_ten_percent_rest(value)
    value.is_a?(Numeric) || raise(ArgumentError, "Value must be a numeric type")
    if @payment_by_ten_percent_rest > 0
      @payment_by_ten_percent_rest -= value
    else
      raise ArgumentError, "No remaining pay with the ten percent method."
    end
  end

    # we calculate how much of the final value is left to be paid by the ten percent method
  protected def deduct_payment_from_by_the_dozen_rest(value)
    value.is_a?(Numeric) || raise(ArgumentError, "Value must be a numeric type")
    if @payment_by_the_dozen_rest > 0
      @payment_by_the_dozen_rest -= value
    else
      raise ArgumentError, "No remaining pay with the payment by the dozen method."
    end
  end

end





class MonthlyPayment < LeavePeriod
  attr_reader :perceived_salary, :payment_in_june, :payment_by_the_dozen, :payment_by_ten_percent

  def initialize(start_date, end_date, salary, end_of_contract=false)
    super(start_date, end_date, salary)

    unless start_date < end_date
      raise ArgumentError, "Start date should be before end date."
    end
    unless start_date.month == end_date.month && start_date.year == end_date.year
      raise ArgumentError, "Start date and end date should be the same month."
    end

    calculate_perceived_salary()
    set_payment_in_june()
    set_payment_by_the_dozen()
    set_payment_by_ten_percent()

    if @end_of_contract
      adjust_payments_end_of_contract()
    end 
  end

  private def calculate_perceived_salary
    if Utils.is_full_month(@start_date, @end_date)
      @perceived_salary = @salary
    else
      # prorata salary for the month
      @perceived_salary = @salary * Utils.calculate_nb_days_prorata(@start_date, @end_date)
    end
    @perceived_salary
  end

  private def set_payment_in_june
    if @start_date.month == 6
      @payment_in_june = super.get_last_period_leave_value
    else
      @payment_in_june = 0.0
    end
  end

  private def set_payment_by_the_dozen
    last_period_leave_value = super.get_last_period_leave_value
    @payment_by_the_dozen = (last_period_leave_value / 12).round(2)
  end

  private def set_payment_by_ten_percent
    @payment_by_ten_percent = @perceived_salary * 0.1
    super.deduct_payment_from_ten_percent_rest(@payment_by_ten_percent)
    # If it's June, we need to add the rest of the last period
    if @start_date.month == 6
      @payment_by_ten_percent += super.get_last_period_ten_percent_rest()
    end
  end

  private def adjust_payments_end_of_contract
    if @end_of_contract
      # Payment in June
      # If it's june we need to pay the last period leave value + this period's value
      @payment_in_june = @payment_in_june + super.final_leave_value

      # Payment by the dozen
      # We need to pay the rest that is due + the accumulation from the current period
      @payment_by_the_dozen = @payment_by_the_dozen + super.payment_by_the_dozen_rest + super.final_leave_value

      # Payment by ten percent
      # We need only need to pay the rest that is due
      @payment_by_ten_percent = @payment_by_ten_percent + super.payment_by_ten_percent_rest
    end
  end
end