require 'date'
require_relative '../../lib/utils'


class LeavePeriod
  attr_reader :start_date, :end_date, :salary
  attr_reader :maintain_salary_leave_value, :ten_percent_leave_value, :final_leave_value
  attr_accessor :nb_months, :nb_leave_days

  def initialize(start_date, end_date, salary)
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

    @start_date = start_date
    @end_date = end_date
    @salary = salary.to_f   
    # @index = index

    calculate_nb_months()
    calculate_nb_leave_days()
    calculate_maintain_salary_leave_value()
    calculate_ten_percent_leave_value()
    set_final_leave_value()
  end

  private def calculate_nb_months
    # If the contract is less than a month
    if @start_date.year == @end_date.year && @start_date.month == @end_date.month
      @nb_months = Utils.calculate_nb_days_prorata(@start_date, @end_date)
      return
    end

    @nb_months = 0
    current = @start_date

    # Handle first month (possibly prorated)
    first_month_end = Date.new(current.year, current.month, -1)
    if Utils.is_full_month(current, first_month_end)
      @nb_months += 1
    else
      @nb_months += Utils.calculate_nb_days_prorata(current, first_month_end)
    end

    # Move to next month
    current = first_month_end.next_day

    # Handle full months in between
    while current < Date.new(@end_date.year, @end_date.month, 1)
      @nb_months += 1
      current = current.next_month
    end

    # Handle last month (possibly prorated)
    last_month_start = Date.new(@end_date.year, @end_date.month, 1)
    if Utils.is_full_month(last_month_start, @end_date)
      @nb_months += 1
    else
      @nb_months += Utils.calculate_nb_days_prorata(last_month_start, @end_date)
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
end


