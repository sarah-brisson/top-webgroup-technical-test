require 'date'
require_relative '../../app/models/monthly_payments'
require_relative '../../lib/utils'

RSpec.describe MonthlyPayment do
  let(:start_date_jan) { Date.new(2023, 1, 1) }
  let(:end_date_jan) { Date.new(2023, 1, 31) }
  let(:start_date_jun) { Date.new(2023, 6, 1) }
  let(:end_date_jun) { Date.new(2023, 6, 30) }
  let(:salary) { 1000.0 }

  # Before each test, ensure Utils methods are mocked to control their behavior
  before do
    allow(Utils).to receive(:is_full_month).and_return(true)
    allow(Utils).to receive(:calculate_nb_days_prorata).and_return(1.0)
  end

  describe '#initialize' do
    context 'with valid arguments' do
      it 'initializes correctly for a full month' do
        monthly_payment = MonthlyPayment.new(start_date_jan, end_date_jan, salary)
        expect(monthly_payment.start_date).to eq(start_date_jan)
        expect(monthly_payment.end_date).to eq(end_date_jan)
        expect(monthly_payment.salary).to eq(salary)
        expect(monthly_payment.last_period_leave_value).to eq(0.0)
        expect(monthly_payment.payment_by_ten_percent_rest).to eq(0.0)
        expect(monthly_payment.perceived_salary).to eq(salary) # Based on default Utils mock
        expect(monthly_payment.payment_in_june).to eq(0.0)
        expect(monthly_payment.payment_by_the_dozen).to eq(0.0) # Because last_period_leave_value is 0
        expect(monthly_payment.payment_by_ten_percent).to eq(salary * 0.1)
      end

      it 'initializes correctly with optional parameters but not end of contract' do
        monthly_payment = MonthlyPayment.new(start_date_jan, end_date_jan, salary, 120.0, 50.0)
        expect(monthly_payment.last_period_leave_value).to eq(120.0)
        expect(monthly_payment.payment_by_ten_percent_rest).to eq(50.0)
        # Initial calculations before adjust_payments_end_of_contract
        expect(monthly_payment.payment_in_june).to eq(0.0)
        expect(monthly_payment.payment_by_the_dozen).to eq(10.0) # 120 / 12
        puts monthly_payment.payment_by_ten_percent
        expect(monthly_payment.payment_by_ten_percent).to eq(salary * 0.1)
      end

      it 'converts salary and leave values to float' do
        monthly_payment = MonthlyPayment.new(start_date_jan, end_date_jan, '1000', '120', '50')
        expect(monthly_payment.salary).to be_a(Float)
        expect(monthly_payment.salary).to eq(1000.0)
        expect(monthly_payment.last_period_leave_value).to be_a(Float)
        expect(monthly_payment.last_period_leave_value).to eq(120.0)
        expect(monthly_payment.payment_by_ten_percent_rest).to be_a(Float)
        expect(monthly_payment.payment_by_ten_percent_rest).to eq(50.0)
      end
    end

    context 'with invalid arguments' do
      it 'raises ArgumentError if start_date is not before end_date' do
        expect { MonthlyPayment.new(start_date_jan, start_date_jan, salary) }
          .to raise_error(ArgumentError, 'Start date should be before end date.')
      end

      it 'raises ArgumentError if start_date and end_date are not in the same month' do
        expect { MonthlyPayment.new(start_date_jan, end_date_jun, salary) }
          .to raise_error(ArgumentError, 'Start date and end date should be the same month.')
      end
    end

    context 'when the end of contract' do
      it 'calls adjust_payments_end_of_contract' do
        monthly_payment = MonthlyPayment.new(start_date_jan, end_date_jan, salary, 120.0, 50.0)
        monthly_payment.final_leave_value = 50.0 # Set this manually for the test
        monthly_payment.payment_by_the_dozen_rest = 20.0 # Set this manually for the test
        monthly_payment.adjust_payments_end_of_contract()
  
        expect(monthly_payment.payment_in_june).to eq(50.0) # 0.0 (initial) + 50.0 (final_leave_value)
        expect(monthly_payment.payment_by_the_dozen).to eq(120.0 / 12 + 20.0 + 50.0) # 10.0 + 20.0 + 50.0 = 80.0
        expect(monthly_payment.payment_by_ten_percent).to eq(salary * 0.1 + 50.0) # 100.0 + 50.0 = 150.0
      end
    end
  end

  describe '#calculate_perceived_salary' do
    let(:monthly_payment) { MonthlyPayment.new(start_date_jan, end_date_jan, salary) }

    context 'when it is a full month' do
      it 'sets perceived_salary to the full salary' do
        allow(Utils).to receive(:is_full_month).and_return(true)
        monthly_payment.calculate_perceived_salary
        expect(monthly_payment.perceived_salary).to eq(salary)
      end
    end

    context 'when it is a prorata month' do
      it 'calculates perceived_salary based on prorata days' do
        allow(Utils).to receive(:is_full_month).and_return(false)
        allow(Utils).to receive(:calculate_nb_days_prorata).and_return(0.5)
        monthly_payment.calculate_perceived_salary
        expect(monthly_payment.perceived_salary).to eq(salary * 0.5)
      end
    end
  end

  describe '#set_payment_in_june' do
    context 'when the start_date is in June' do
      it 'sets payment_in_june to last_period_leave_value' do
        monthly_payment = MonthlyPayment.new(start_date_jun, end_date_jun, salary, 200.0)
        monthly_payment.set_payment_in_june
        expect(monthly_payment.payment_in_june).to eq(200.0)
      end
    end

    context 'when the start_date is not in June' do
      it 'sets payment_in_june to 0.0' do
        monthly_payment = MonthlyPayment.new(start_date_jan, end_date_jan, salary, 200.0)
        monthly_payment.set_payment_in_june
        expect(monthly_payment.payment_in_june).to eq(0.0)
      end
    end
  end

  describe '#set_payment_by_the_dozen' do
    context 'when last_period_leave_value is not 0' do
      it 'calculates payment_by_the_dozen' do
        monthly_payment = MonthlyPayment.new(start_date_jan, end_date_jan, salary, 120.0)
        monthly_payment.set_payment_by_the_dozen
        expect(monthly_payment.payment_by_the_dozen).to eq(10.0) # 120 / 12
      end

      it 'rounds the payment to 2 decimal places' do
        monthly_payment = MonthlyPayment.new(start_date_jan, end_date_jan, salary, 100.0)
        monthly_payment.set_payment_by_the_dozen
        expect(monthly_payment.payment_by_the_dozen).to eq(8.33) # 100 / 12
      end
    end

    context 'when last_period_leave_value is 0' do
      it 'leaves payment_by_the_dozen as 0' do
        monthly_payment = MonthlyPayment.new(start_date_jan, end_date_jan, salary, 0.0)
        monthly_payment.set_payment_by_the_dozen
        expect(monthly_payment.payment_by_the_dozen).to eq(0)
      end
    end
  end

  describe '#set_payment_by_ten_percent' do
    let(:monthly_payment) { MonthlyPayment.new(start_date_jan, end_date_jan, salary) }

    context 'when start_date is not in June' do
      it 'calculates payment_by_ten_percent as 10% of perceived_salary' do
        monthly_payment.set_payment_by_ten_percent
        expect(monthly_payment.payment_by_ten_percent).to eq(salary * 0.1)
      end
    end

    context 'when start_date is in June' do
      it 'adds payment_by_ten_percent_rest to the calculation' do
        monthly_payment = MonthlyPayment.new(start_date_jun, end_date_jun, salary, 0.0, 50.0)
        monthly_payment.set_payment_by_ten_percent
        expect(monthly_payment.payment_by_ten_percent).to eq(salary * 0.1 + 50.0)
      end
    end
  end

  describe '#adjust_payments_end_of_contract' do
    let(:monthly_payment) { MonthlyPayment.new(start_date_jan, end_date_jan, salary, 120.0, 50.0) }

    before do
      # Set up state as if it just finished initialization before adjustment
      monthly_payment.final_leave_value = 50.0
      monthly_payment.payment_by_the_dozen_rest = 20.0
      # Re-run initial calculations to ensure they are consistent before adjustment
      monthly_payment.calculate_perceived_salary
      monthly_payment.set_payment_in_june
      monthly_payment.set_payment_by_the_dozen
      monthly_payment.set_payment_by_ten_percent
    end

    context 'when end_of_contract is true' do
      it 'adjusts payment_in_june' do
        initial_payment_in_june = monthly_payment.payment_in_june # This would be 0.0 for Jan
        monthly_payment.adjust_payments_end_of_contract
        expect(monthly_payment.payment_in_june).to eq(initial_payment_in_june + monthly_payment.final_leave_value)
      end

      it 'adjusts payment_by_the_dozen' do
        initial_payment_by_the_dozen = monthly_payment.payment_by_the_dozen # This would be 10.0 for Jan
        monthly_payment.adjust_payments_end_of_contract
        expect(monthly_payment.payment_by_the_dozen).to eq(initial_payment_by_the_dozen + monthly_payment.payment_by_the_dozen_rest + monthly_payment.final_leave_value)
      end

      it 'adjusts payment_by_ten_percent' do
        initial_payment_by_ten_percent = monthly_payment.payment_by_ten_percent # This would be 100.0 for Jan
        monthly_payment.adjust_payments_end_of_contract
        expect(monthly_payment.payment_by_ten_percent).to eq(initial_payment_by_ten_percent + monthly_payment.payment_by_ten_percent_rest)
      end
    end

    context 'when end_of_contract is false' do
      let(:monthly_payment_no_contract_end) { MonthlyPayment.new(start_date_jan, end_date_jan, salary, 120.0, 50.0) }

      before do
        monthly_payment_no_contract_end.final_leave_value = 50.0
        monthly_payment_no_contract_end.payment_by_the_dozen_rest = 20.0
        monthly_payment_no_contract_end.calculate_perceived_salary
        monthly_payment_no_contract_end.set_payment_in_june
        monthly_payment_no_contract_end.set_payment_by_the_dozen
        monthly_payment_no_contract_end.set_payment_by_ten_percent
      end

      it 'adjusts payment_in_june' do
        initial_payment_in_june = monthly_payment_no_contract_end.payment_in_june
        monthly_payment_no_contract_end.adjust_payments_end_of_contract
        expect(monthly_payment_no_contract_end.payment_in_june).to eq(50)
        # 0.0 (initial) + 50.0 (leave value of current period)
      end

      it 'does not adjust payment_by_the_dozen' do
        initial_payment_by_the_dozen = monthly_payment_no_contract_end.payment_by_the_dozen
        monthly_payment_no_contract_end.adjust_payments_end_of_contract
        expect(monthly_payment_no_contract_end.payment_by_the_dozen).to eq(80.0) 
        # 10.0 + 20.0 + 50.0 => payment by the dozen + rest of payment by the dozen + leave value of current period
      end

      it 'does not adjust payment_by_ten_percent' do
        initial_payment_by_ten_percent = monthly_payment_no_contract_end.payment_by_ten_percent
        monthly_payment_no_contract_end.adjust_payments_end_of_contract
        expect(monthly_payment_no_contract_end.payment_by_ten_percent).to eq(150) 
        # 100.0 + 50.0 => payment by ten percent + rest of payment by ten percent
      end
    end
  end
end