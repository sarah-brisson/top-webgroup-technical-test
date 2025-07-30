require 'date'
require_relative '../../app/models/contract'

RSpec.describe Contract do
  let(:contract) { Contract.new(Date.new(2020,1,1), Date.new(2021,9,30), 1000) }

  describe '#initialize' do
    it 'creates a contract with valid dates and salary' do
      expect(contract.start_date).to eq(Date.new(2020,1,1))
      expect(contract.end_date).to eq(Date.new(2021,9,30))
      expect(contract.salary).to eq(1000.0)
    end

    it 'raises error for invalid date types' do
      expect { Contract.new('2020-01-01', Date.new(2022,9,30), 1000) }.to raise_error(ArgumentError)
    end

    it 'raises error if start_date >= end_date' do
      expect { Contract.new(Date.new(2022,9,30), Date.new(2020,1,1), 1000) }.to raise_error(ArgumentError)
    end

    it 'raises error for non-numeric salary' do
      expect { Contract.new(Date.new(2020,1,1), Date.new(2022,9,30), 'abc') }.to raise_error(ArgumentError)
    end

    it 'raises error if salary is under 200' do
      expect { Contract.new(Date.new(2020,1,1), Date.new(2022,9,30), 100) }.to raise_error(ArgumentError)
    end

    it 'raises error if salary is above 1200' do
      expect { Contract.new(Date.new(2020,1,1), Date.new(2022,9,30), 1300) }.to raise_error(ArgumentError)
    end
  end


  describe '#split_into_leave_periods' do
    it 'splits contract into correct leave periods' do
      periods = contract.split_into_leave_periods
      expect(contract.periods.size).to eq(3)
      expect(contract.periods[0].start_date).to eq(Date.new(2020,1,1))
      expect(contract.periods[0].end_date).to eq(Date.new(2020,5,31))
      expect(contract.periods[1].start_date).to eq(Date.new(2020,6,1))
      expect(contract.periods[1].end_date).to eq(Date.new(2021,5,31))
      expect(contract.periods[2].start_date).to eq(Date.new(2021,6,1))
      expect(contract.periods[2].end_date).to eq(Date.new(2021,9,30))
    end
  end
end