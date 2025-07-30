require 'date'
require_relative '../lib/utils'

RSpec.describe Utils do
  describe '.is_full_month' do
    it 'returns true for full month of January' do
      expect(Utils.is_full_month(Date.new(2021, 1, 1), Date.new(2021, 1, 31))).to be true
    end

    it 'returns true for full month of February (non-leap year)' do
      expect(Utils.is_full_month(Date.new(2021, 2, 1), Date.new(2021, 2, 28))).to be true
    end

    it 'returns false when end date is not the last day of the month' do
      expect(Utils.is_full_month(Date.new(2021, 1, 1), Date.new(2021, 1, 30))).to be false
    end

    it 'returns false when start date is not the first of the month' do
      expect(Utils.is_full_month(Date.new(2021, 1, 2), Date.new(2021, 1, 31))).to be false
    end
  end

  describe '.calculate_nb_days_in_a_month' do
    it 'returns 31 for full January' do
      expect(Utils.calculate_nb_days_in_a_month(Date.new(2021, 1, 1), Date.new(2021, 1, 31))).to eq 31
    end

    it 'returns 8 for Jan 24 to Jan 31' do
      expect(Utils.calculate_nb_days_in_a_month(Date.new(2021, 1, 24), Date.new(2021, 1, 31))).to eq 8
    end

    it 'returns 12 for Jan 1 to Jan 12' do
      expect(Utils.calculate_nb_days_in_a_month(Date.new(2021, 1, 1), Date.new(2021, 1, 12))).to eq 12
    end

    it 'returns false for mismatched months' do
      expect(Utils.calculate_nb_days_in_a_month(Date.new(2021, 1, 28), Date.new(2021, 2, 1))).to be false
    end
  end

  describe '.calculate_nb_days_prorata' do
    it 'returns 1.0 for full month' do
      result = Utils.calculate_nb_days_prorata(Date.new(2021, 1, 1), Date.new(2021, 1, 31))
      expect(result).to eq 1.0
    end

    it 'returns correct ratio for partial month' do
      result = Utils.calculate_nb_days_prorata(Date.new(2021, 1, 15), Date.new(2021, 1, 31))
      expect(result).to eq ((17.0 / 31).round(2))
    end
  end
end
