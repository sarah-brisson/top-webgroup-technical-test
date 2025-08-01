require 'date'
require_relative '../../app/models/leave_period'

RSpec.describe LeavePeriod do
  describe '#initialize' do
    it 'raises error if end_date is after May 31 of next year' do
      expect {
        LeavePeriod.new(Date.new(2020,6,1), Date.new(2021,6,1), 1000)
      }.to raise_error(ArgumentError)
    end

    it 'allows end_date up to May 31 of next year' do
      expect {
        LeavePeriod.new(Date.new(2020,6,1), Date.new(2021,5,31), 1000)
      }.not_to raise_error
    end
  end

  describe '#calculate_nb_months' do
    it 'returns 0.94 for period from 03-05 to 31-05' do
      lp = LeavePeriod.new(Date.new(2020,5,3), Date.new(2020,5,31), 1000)
      expect(lp.nb_months).to eq(0.94)
    end

    it 'returns 2.55 for period from 15-03 to 31-05' do
      lp = LeavePeriod.new(Date.new(2020,3,15), Date.new(2020,5,31), 1000)
      expect(lp.nb_months).to eq(2.55)
    end
  end

  describe '#calculate_nb_leave_days' do
    it 'returns 2.35 for period from 03-05 to 31-05' do
      lp = LeavePeriod.new(Date.new(2020,5,3), Date.new(2020,5,31), 1000)
      expect(lp.nb_leave_days).to eq(2.35)
    end
  end
  
  describe '#maintain_salary_method' do
    it 'returns 146.63€ for period from 03-05 to 31-05' do
      lp = LeavePeriod.new(Date.new(2020,3,15), Date.new(2020,5,31), 506)
      expect(lp.maintain_salary_leave_value).to eq(146.63)
    end
  end

  describe '#10_percent_method' do
    it 'returns 129.03€ for period from 03-05 to 31-05' do
      lp = LeavePeriod.new(Date.new(2020,3,15), Date.new(2020,5,31), 506)
      expect(lp.ten_percent_leave_value).to eq(129.03)
    end
  end

  describe 'final_leave_value' do
    it 'returns 146.63€ for period from 03-05 to 31-05' do
      lp = LeavePeriod.new(Date.new(2020,3,15), Date.new(2020,5,31), 506)
      expect(lp.final_leave_value).to eq(146.63)
    end
  end
end