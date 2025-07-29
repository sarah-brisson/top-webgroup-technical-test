require 'date'

class Contract
  attr_accessor :start_date, :end_date, :salary

  def initialize(start_date, end_date, salary)
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

      periods << LeavePeriod.new(current_start, period_end, @salary)
      current_start = period_end + 1
    end

    periods
  end
end


class LeavePeriod < Contract
  attr_accessor :maintain_salary_leave_value, :ten_percent_leave_value, :final_leave_value

  def initialize(start_date, end_date, salary, maintain_salary_leave_value = 0.0, ten_percent_leave_value = 0.0, final_leave_value = 0.0)
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

    @maintain_salary_leave_value = maintain_salary_leave_value.to_f
    @ten_percent_leave_value ten_percent_leave_value.to_f
    @final_leave_value = final_leave_value.to_f
  end
end


class MonthlyPayment < LeavePeriod
  attr_accessor :perceived_salary, :payment_by_ten_percent

  def initialize(start_date, end_date, salary, perceived_salary=0.0, payment_by_ten_percent=0.0)
    super(start_date, end_date, salary)

    @perceived_salary = perceived_salary.to_f
    @payment_by_ten_percent = payment_by_ten_percent.to_f
  end
end