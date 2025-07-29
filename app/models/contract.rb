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
  end
end


class LeavePeriod < Contract
  attr_accessor :nb_months, :nb_leave_days
  attr_reader :maintain_salary_leave_value, :ten_percent_leave_value, :final_leave_value

  def initialize(start_date, end_date, salary, index=0, nb_months=0, nb_leave_days=0, maintain_salary_leave_value=0.0, ten_percent_leave_value=0.0, final_leave_value=0.0)
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

    calculate_nb_months()
    calculate_nb_leave_days()
    calculate_maintain_salary_leave_value()
    calculate_ten_percent_leave_value()
    set_final_leave_value()
  end

  def calculate_nb_months
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

  def calculate_nb_leave_days
    if @nb_months > 0
      @nb_leave_days = (@nb_months*2.5).round(3)
    else
      @nb_leave_days = 0
    end
    @nb_leave_days
  end

  def calculate_maintain_salary_leave_value
    if @nb_leave_days > 0
      @maintain_salary_leave_value = ((@salary / 22) * @nb_leave_days).round(2)
    else
      @maintain_salary_leave_value = 0.0
    end
    @maintain_salary_leave_value
  end

  def calculate_ten_percent_leave_value
    if @nb_leave_days > 0
      # 10% of the salary for the entire period
      @ten_percent_leave_value = (@salary * @nb_months * 0.1).round(2)
    else
      @ten_percent_leave_value = 0.0
    end
    @ten_percent_leave_value
  end

  def set_final_leave_value
    if @maintain_salary_leave_value > @ten_percent_leave_value
      @final_leave_value = @maintain_salary_leave_value
    else
      @final_leave_value = @ten_percent_leave_value
    end
    @final_leave_value
  end

  def get_last_period_leave_value
    # Returns the leave value of the last period
    if index > 0
      previous_period = periods[index-1] 
      previous_leave_value = previous_period.final_leave_value
      return previous_leave_value
    else
      return 0.0
    end
  end

end
class MonthlyPayment < LeavePeriod
  attr_reader :perceived_salary, :payment_in_june, :payment_by_the_dozen, :payment_by_ten_percent

  def initialize(start_date, end_date, salary)
  # def initialize(start_date, end_date, salary, perceived_salary=0.0, payment_in_june=0.0, payment_by_the_dozen=0.0, payment_by_ten_percent=0.0)
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
  end

  def calculate_perceived_salary
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
      @payment_in_june = super.get_last_period_leave_value
    else
      # TODO SI C'EST LE DERNIER MOIS DU CONTRAT
      @payment_in_june = 0.0
    end
    @payment_in_june
  end

  def set_payment_by_the_dozen
    last_period_leave_value = super.get_last_period_leave_value
    @payment_by_the_dozen = (last_period_leave_value / 12).round(2)
    # TODO SI C'EST LE DERNIER MOIS DU CONTRAT
  end
end