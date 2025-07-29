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
end


class LeavePeriod < Contract
  attr_accessor :maintain_salary_leave_value, :ten_percent_leave_value, :final_leave_value

  def initialize(start_date, end_date, salary, maintain_salary_leave_value = 0.0, ten_percent_leave_value = 0.0, final_leave_value = 0.0)
    super(start_date, end_date, salary)

    # Ensure leave period is from June 1 to May 31 of the next year
    unless start_date.month >= 6 && start_date.day == 1
      raise ArgumentError, "LeavePeriod must start on June 1."
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