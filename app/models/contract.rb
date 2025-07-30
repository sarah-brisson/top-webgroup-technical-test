require 'date'
require_relative '../../lib/utils'
require_relative './leave_period'

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

      periods << LeavePeriod.new(current_start, period_end, @salary)
      current_start = period_end + 1
    end

    @periods = periods
    periods
  end
end

