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

import { render, screen, fireEvent } from '@testing-library/react'
import HumanGateDialog from '@/components/HumanGateDialog'
import AiDegradedBanner from '@/components/AiDegradedBanner'

beforeEach(() => {
  jest.clearAllMocks()
})

describe('HumanGateDialog', () => {
  const payload = { Тип: 'квартира', Площа: 85, Камери: 6 }

  it('renders payload as JSON', () => {
    render(<HumanGateDialog payload={payload} onConfirm={jest.fn()} onCancel={jest.fn()} />)
    expect(screen.getByText(/квартира/)).toBeTruthy()
    expect(screen.getByText(/85/)).toBeTruthy()
    expect(screen.getByText(/6/)).toBeTruthy()
  })

  it('confirm button is disabled initially', () => {
    render(<HumanGateDialog payload={payload} onConfirm={jest.fn()} onCancel={jest.fn()} />)
    const btn = screen.getByText('Запустити AI')
    expect(btn).toBeDisabled()
  })

  it('confirm button enables after checkbox', () => {
    render(<HumanGateDialog payload={payload} onConfirm={jest.fn()} onCancel={jest.fn()} />)
    const checkbox = screen.getByRole('checkbox')
    fireEvent.click(checkbox)
    const btn = screen.getByText('Запустити AI')
    expect(btn).not.toBeDisabled()
  })

  it('calls onConfirm when confirmed', () => {
    const onConfirm = jest.fn()
    render(<HumanGateDialog payload={payload} onConfirm={onConfirm} onCancel={jest.fn()} />)
    fireEvent.click(screen.getByRole('checkbox'))
    fireEvent.click(screen.getByText('Запустити AI'))
    expect(onConfirm).toHaveBeenCalledTimes(1)
  })

  it('calls onCancel when cancel clicked', () => {
    const onCancel = jest.fn()
    render(<HumanGateDialog payload={payload} onConfirm={jest.fn()} onCancel={onCancel} />)
    fireEvent.click(screen.getByText('Скасувати'))
    expect(onCancel).toHaveBeenCalledTimes(1)
  })
})

describe('AiDegradedBanner', () => {
  it('renders nothing for primary level', () => {
    const { container } = render(<AiDegradedBanner level="primary" />)
    expect(container.innerHTML).toBe('')
  })

  it('renders fallback message', () => {
    render(<AiDegradedBanner level="fallback" />)
    expect(screen.getByText(/частково доступний/)).toBeTruthy()
  })

  it('renders manual message', () => {
    render(<AiDegradedBanner level="manual" />)
    expect(screen.getByText(/недоступний/)).toBeTruthy()
  })
})
