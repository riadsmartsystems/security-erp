jest.mock('axios', () => {
  const mockInstance = {
    get: jest.fn(),
    post: jest.fn(),
    interceptors: {
      request: { use: jest.fn() },
    },
  }
  return {
    __esModule: true,
    default: {
      create: jest.fn(() => mockInstance),
    },
  }
})

jest.mock('@/components/TurnstileWidget', () => {
  return {
    __esModule: true,
    default: ({ onVerify }: { onVerify: (token: string) => void }) => (
      <div data-testid="turnstile-mock">
        <button data-testid="verify-captcha" onClick={() => onVerify('test-token-123')}>
          Verify Captcha
        </button>
      </div>
    ),
  }
})

import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import CalculatorPage from '@/app/calculator/page'
import { submitCalculator } from '@/lib/api'

const axios = require('axios').default
const apiInstance = axios.create()

jest.mock('@/lib/api', () => {
  const actual = jest.requireActual('@/lib/api')
  return {
    ...actual,
    submitCalculator: jest.fn(),
  }
})

const mockedSubmitCalculator = submitCalculator as jest.MockedFunction<typeof submitCalculator>

beforeEach(() => {
  jest.clearAllMocks()
})

describe('CalculatorPage', () => {
  it('renders step 1 form fields', () => {
    render(<CalculatorPage />)

    expect(screen.getByLabelText(/Тип системи/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/Площа/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/Кількість камер/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/Дні зберігання архіву/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Далі/i })).toBeInTheDocument()
  })

  it('navigates to step 2 on "Далі"', () => {
    render(<CalculatorPage />)

    fireEvent.change(screen.getByLabelText(/Тип системи/i), { target: { value: 'CCTV IP' } })
    fireEvent.change(screen.getByLabelText(/Площа/i), { target: { value: '100' } })

    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    expect(screen.getByLabelText(/Ім'я/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/Телефон/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/Email/i)).toBeInTheDocument()
  })

  it('renders step 2 form fields', () => {
    render(<CalculatorPage />)

    fireEvent.change(screen.getByLabelText(/Тип системи/i), { target: { value: 'Access Control' } })
    fireEvent.change(screen.getByLabelText(/Площа/i), { target: { value: '50' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    expect(screen.getByLabelText(/Ім'я \*/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/Телефон \*/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/Email \(опціонально\)/i)).toBeInTheDocument()
  })

  it('navigates to step 3 on "Далі"', () => {
    render(<CalculatorPage />)

    fireEvent.change(screen.getByLabelText(/Тип системи/i), { target: { value: 'Alarm' } })
    fireEvent.change(screen.getByLabelText(/Площа/i), { target: { value: '200' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    fireEvent.change(screen.getByLabelText(/Ім'я \*/i), { target: { value: 'Тест' } })
    fireEvent.change(screen.getByLabelText(/Телефон \*/i), { target: { value: '+380501234567' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    expect(screen.getByRole('button', { name: /Розрахувати/i })).toBeInTheDocument()
  })

  it('shows "Назад" and navigates back', () => {
    render(<CalculatorPage />)

    fireEvent.change(screen.getByLabelText(/Тип системи/i), { target: { value: 'CCTV IP' } })
    fireEvent.change(screen.getByLabelText(/Площа/i), { target: { value: '100' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    expect(screen.getByRole('button', { name: /Назад/i })).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: /Назад/i }))

    expect(screen.getByLabelText(/Тип системи/i)).toBeInTheDocument()
    expect(screen.queryByLabelText(/Ім'я/i)).not.toBeInTheDocument()
  })

  it('validates required fields step 1', () => {
    render(<CalculatorPage />)

    const nextButton = screen.getByRole('button', { name: /Далі/i })
    expect(nextButton).toBeDisabled()

    fireEvent.change(screen.getByLabelText(/Тип системи/i), { target: { value: 'CCTV IP' } })
    expect(nextButton).toBeDisabled()

    fireEvent.change(screen.getByLabelText(/Площа/i), { target: { value: '100' } })
    expect(nextButton).not.toBeDisabled()
  })

  it('validates required fields step 2', () => {
    render(<CalculatorPage />)

    fireEvent.change(screen.getByLabelText(/Тип системи/i), { target: { value: 'CCTV IP' } })
    fireEvent.change(screen.getByLabelText(/Площа/i), { target: { value: '100' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    const nextButton = screen.getByRole('button', { name: /Далі/i })
    expect(nextButton).toBeDisabled()

    fireEvent.change(screen.getByLabelText(/Ім'я \*/i), { target: { value: 'Тест' } })
    expect(nextButton).toBeDisabled()

    fireEvent.change(screen.getByLabelText(/Телефон \*/i), { target: { value: '+380501234567' } })
    expect(nextButton).not.toBeDisabled()
  })

  it('submit calls API with correct payload', async () => {
    mockedSubmitCalculator.mockResolvedValue({
      submission_name: 'CALC-001',
      estimated_total: 15000,
      matched_scenario: 'CCTV IP 100m²',
      status: 'new',
    })

    render(<CalculatorPage />)

    fireEvent.change(screen.getByLabelText(/Тип системи/i), { target: { value: 'CCTV IP' } })
    fireEvent.change(screen.getByLabelText(/Площа/i), { target: { value: '100' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    fireEvent.change(screen.getByLabelText(/Ім'я \*/i), { target: { value: 'Олексій' } })
    fireEvent.change(screen.getByLabelText(/Телефон \*/i), { target: { value: '+380501234567' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    fireEvent.click(screen.getByTestId('verify-captcha'))
    fireEvent.click(screen.getByRole('button', { name: /Розрахувати/i }))

    await waitFor(() => {
      expect(mockedSubmitCalculator).toHaveBeenCalledWith({
        object_type: 'CCTV IP',
        area_m2: 100,
        cameras_count: 0,
        archive_days: 0,
        contact_name: 'Олексій',
        contact_phone: '+380501234567',
        contact_email: '',
        captcha_token: 'test-token-123',
      })
    })
  })

  it('shows estimated_total on success', async () => {
    mockedSubmitCalculator.mockResolvedValue({
      submission_name: 'CALC-002',
      estimated_total: 25000,
      matched_scenario: 'CCTV Analog',
      status: 'new',
    })

    render(<CalculatorPage />)

    fireEvent.change(screen.getByLabelText(/Тип системи/i), { target: { value: 'CCTV Analog' } })
    fireEvent.change(screen.getByLabelText(/Площа/i), { target: { value: '200' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    fireEvent.change(screen.getByLabelText(/Ім'я \*/i), { target: { value: 'Іван' } })
    fireEvent.change(screen.getByLabelText(/Телефон \*/i), { target: { value: '+380671234567' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    fireEvent.click(screen.getByTestId('verify-captcha'))
    fireEvent.click(screen.getByRole('button', { name: /Розрахувати/i }))

    await waitFor(() => {
      expect(screen.getByText(/25\s?000/)).toBeInTheDocument()
      expect(screen.getByText(/грн/)).toBeInTheDocument()
      expect(screen.getByText(/CALC-002/)).toBeInTheDocument()
    })
  })

  it('shows error on 429', async () => {
    mockedSubmitCalculator.mockRejectedValue({
      response: { status: 429 },
    })

    render(<CalculatorPage />)

    fireEvent.change(screen.getByLabelText(/Тип системи/i), { target: { value: 'Alarm' } })
    fireEvent.change(screen.getByLabelText(/Площа/i), { target: { value: '50' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    fireEvent.change(screen.getByLabelText(/Ім'я \*/i), { target: { value: 'Тест' } })
    fireEvent.change(screen.getByLabelText(/Телефон \*/i), { target: { value: '+380501111111' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    fireEvent.click(screen.getByTestId('verify-captcha'))
    fireEvent.click(screen.getByRole('button', { name: /Розрахувати/i }))

    await waitFor(() => {
      expect(screen.getByText(/Забагато запитів/)).toBeInTheDocument()
    })
  })

  it('shows error on 502', async () => {
    mockedSubmitCalculator.mockRejectedValue({
      response: { status: 502 },
    })

    render(<CalculatorPage />)

    fireEvent.change(screen.getByLabelText(/Тип системи/i), { target: { value: 'Network' } })
    fireEvent.change(screen.getByLabelText(/Площа/i), { target: { value: '300' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    fireEvent.change(screen.getByLabelText(/Ім'я \*/i), { target: { value: 'Тест' } })
    fireEvent.change(screen.getByLabelText(/Телефон \*/i), { target: { value: '+380672222222' } })
    fireEvent.click(screen.getByRole('button', { name: /Далі/i }))

    fireEvent.click(screen.getByTestId('verify-captcha'))
    fireEvent.click(screen.getByRole('button', { name: /Розрахувати/i }))

    await waitFor(() => {
      expect(screen.getByText(/Сервіс тимчасово недоступний/)).toBeInTheDocument()
    })
  })
})
