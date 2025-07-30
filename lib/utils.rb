require 'date'

module Utils
  def self.is_full_month(start_date, end_date)
    return false if start_date.day != 1
    return false if end_date.month != start_date.month || end_date.year != start_date.year
    # get number of days in the month
    days_in_month = Date.new(start_date.year, start_date.month, -1).day
    return false if end_date.day != days_in_month
    return true
  end

  def self.calculate_nb_days_in_a_month(start_date, end_date)
      return false if end_date.month != start_date.month || end_date.year != start_date.year
      return (end_date - start_date).to_i + 1
  end

  def self.calculate_nb_days_prorata(start_date, end_date)
      nb_days_in_a_period = calculate_nb_days_in_a_month(start_date, end_date)
      days_in_month = Date.new(start_date.year, start_date.month, -1).day
      return (nb_days_in_a_period.to_f / days_in_month).round(2)
  end
end