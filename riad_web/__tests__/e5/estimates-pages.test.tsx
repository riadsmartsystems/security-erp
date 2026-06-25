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

jest.mock('next/navigation', () => ({
  useRouter: () => ({ push: jest.fn(), back: jest.fn() }),
  useParams: () => ({ id: 'AI-EST-001' }),
}))

jest.mock('@/lib/api', () => ({
  buildEstimate: jest.fn(),
  listSiteBriefs: jest.fn(),
  fetchSiteBrief: jest.fn(),
  fetchAiDegradation: jest.fn(),
  fetchEstimate: jest.fn(),
  reviewEstimate: jest.fn(),
  confirmEstimate: jest.fn(),
}))

import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import NewEstimatePage from '@/app/estimates/new/page'
import EstimateDetailPage from '@/app/estimates/[id]/page'
import {
  buildEstimate,
  listSiteBriefs,
  fetchSiteBrief,
  fetchAiDegradation,
  fetchEstimate,
  reviewEstimate,
  confirmEstimate,
} from '@/lib/api'

const mockedBuildEstimate = buildEstimate as jest.MockedFunction<typeof buildEstimate>
const mockedListSiteBriefs = listSiteBriefs as jest.MockedFunction<typeof listSiteBriefs>
const mockedFetchSiteBrief = fetchSiteBrief as jest.MockedFunction<typeof fetchSiteBrief>
const mockedFetchAiDegradation = fetchAiDegradation as jest.MockedFunction<typeof fetchAiDegradation>
const mockedFetchEstimate = fetchEstimate as jest.MockedFunction<typeof fetchEstimate>
const mockedReviewEstimate = reviewEstimate as jest.MockedFunction<typeof reviewEstimate>
const mockedConfirmEstimate = confirmEstimate as jest.MockedFunction<typeof confirmEstimate>

beforeEach(() => {
  jest.clearAllMocks()
  window.alert = jest.fn()
  mockedListSiteBriefs.mockResolvedValue([
    { name: 'SB-001', brief_name: 'Офіс ТзОВ Ромашка' },
    { name: 'SB-002', brief_name: 'Склад №3' },
  ])
  mockedFetchAiDegradation.mockResolvedValue({ level: 'primary', providers: [], message: '' })
  mockedFetchSiteBrief.mockResolvedValue({
    name: 'SB-001',
    brief_name: 'Офіс ТзОВ Ромашка',
    object_type: 'офіс',
    area_m2: 120,
    cameras_count: 8,
    camera_type: 'IP',
    archive_days: 30,
    access_control: 0,
    intercom: 1,
    alarm: 0,
    network_needed: 1,
    power_backup: 0,
    tech_notes: null,
    source: null,
  })
})

describe('estimates/new page', () => {
  it('loads site briefs on mount', async () => {
    render(<NewEstimatePage />)
    await waitFor(() => {
      expect(screen.getByText('Офіс ТзОВ Ромашка')).toBeTruthy()
      expect(screen.getByText('Склад №3')).toBeTruthy()
    })
  })

  it('shows variant options', () => {
    render(<NewEstimatePage />)
    expect(screen.getByText('Бюджетний')).toBeTruthy()
    expect(screen.getByText('Оптимальний')).toBeTruthy()
    expect(screen.getByText('Преміум')).toBeTruthy()
  })

  it('shows human gate dialog after clicking Запустити AI', async () => {
    render(<NewEstimatePage />)
    await waitFor(() => {
      expect(screen.getByText('Офіс ТзОВ Ромашка')).toBeTruthy()
    })

    const select = screen.getByLabelText(/Site Brief/)
    fireEvent.change(select, { target: { value: 'SB-001' } })

    await waitFor(() => {
      expect(screen.getByText(/офіс/)).toBeTruthy()
    })

    fireEvent.click(screen.getByText('Запустити AI'))
    expect(screen.getByText('Підтвердження AI-запиту')).toBeTruthy()
    const jsonPayload = screen.getByText(/"variant": "optimal"/)
    expect(jsonPayload).toBeTruthy()
    expect(jsonPayload.textContent).toContain('120')
    expect(jsonPayload.textContent).toContain('8')
  })

  it('calls buildEstimate after gate confirmation', async () => {
    mockedBuildEstimate.mockResolvedValue({ name: 'AI-EST-001', status: 'Draft', origin: 'ai_primary' })

    render(<NewEstimatePage />)
    await waitFor(() => {
      expect(screen.getByText('Офіс ТзОВ Ромашка')).toBeTruthy()
    })

    fireEvent.change(screen.getByLabelText(/Site Brief/), { target: { value: 'SB-001' } })
    await waitFor(() => {
      expect(screen.getByText(/офіс/)).toBeTruthy()
    })

    fireEvent.click(screen.getByText('Запустити AI'))
    fireEvent.click(screen.getByRole('checkbox'))
    const dialogBtns = screen.getAllByText('Запустити AI')
    fireEvent.click(dialogBtns[dialogBtns.length - 1])

    await waitFor(() => {
      expect(mockedBuildEstimate).toHaveBeenCalledWith({
        site_brief_name: 'SB-001',
        variant: 'optimal',
      })
    })
  })
})

describe('estimates/[id] page', () => {
  it('shows review buttons for ai_primary origin with non-Approved status', async () => {
    mockedFetchEstimate.mockResolvedValue({
      name: 'AI-EST-001',
      site_brief: 'SB-001',
      variant: 'optimal',
      origin: 'ai_primary',
      status: 'ai_primary',
      reviewed_by: null,
      reviewed_at: null,
      ai_result: null,
      total_cost: null,
      total_margin: null,
      items: [],
    })

    render(<EstimateDetailPage />)
    await waitFor(() => {
      expect(screen.getByText('Затвердити')).toBeTruthy()
      expect(screen.getByText('Відхилити')).toBeTruthy()
    })
  })

  it('hides review buttons for manual origin', async () => {
    mockedFetchEstimate.mockResolvedValue({
      name: 'AI-EST-002',
      site_brief: 'SB-001',
      variant: 'budget',
      origin: 'manual',
      status: 'Draft',
      reviewed_by: null,
      reviewed_at: null,
      ai_result: null,
      total_cost: null,
      total_margin: null,
      items: [],
    })

    render(<EstimateDetailPage />)
    await waitFor(() => {
      expect(screen.queryByText('Затвердити')).toBeNull()
      expect(screen.queryByText('Відхилити')).toBeNull()
    })
  })

  it('shows confirm button when status=Approved and reviewed_by present', async () => {
    mockedFetchEstimate.mockResolvedValue({
      name: 'AI-EST-003',
      site_brief: 'SB-001',
      variant: 'optimal',
      origin: 'ai_primary',
      status: 'Approved',
      reviewed_by: 'engineer@riad.fun',
      reviewed_at: '2026-06-25T10:00:00',
      ai_result: null,
      total_cost: 150000,
      total_margin: 30000,
      items: [],
    })

    render(<EstimateDetailPage />)
    await waitFor(() => {
      expect(screen.getByText('Підтвердити → Quotation')).toBeTruthy()
      expect(screen.queryByText('Затвердити')).toBeNull()
    })
  })

  it('hides confirm button when reviewed_by is empty', async () => {
    mockedFetchEstimate.mockResolvedValue({
      name: 'AI-EST-004',
      site_brief: 'SB-001',
      variant: 'optimal',
      origin: 'ai_primary',
      status: 'Approved',
      reviewed_by: '',
      reviewed_at: null,
      ai_result: null,
      total_cost: null,
      total_margin: null,
      items: [],
    })

    render(<EstimateDetailPage />)
    await waitFor(() => {
      expect(screen.queryByText('Підтвердити → Quotation')).toBeNull()
    })
  })

  it('calls reviewEstimate on Затвердити click', async () => {
    mockedReviewEstimate.mockResolvedValue({ name: 'AI-EST-001', status: 'Approved', reviewed_by: 'test' })
    mockedFetchEstimate.mockResolvedValue({
      name: 'AI-EST-001',
      site_brief: 'SB-001',
      variant: 'optimal',
      origin: 'ai_primary',
      status: 'ai_primary',
      reviewed_by: null,
      reviewed_at: null,
      ai_result: null,
      total_cost: null,
      total_margin: null,
      items: [],
    })

    render(<EstimateDetailPage />)
    await waitFor(() => {
      expect(screen.getByText('Затвердити')).toBeTruthy()
    })

    fireEvent.click(screen.getByText('Затвердити'))
    await waitFor(() => {
      expect(mockedReviewEstimate).toHaveBeenCalledWith('AI-EST-001', { decision: 'approved' })
    })
  })

  it('calls confirmEstimate on confirm click', async () => {
    mockedConfirmEstimate.mockResolvedValue({ quotation_name: 'QTN-001' })
    mockedFetchEstimate.mockResolvedValue({
      name: 'AI-EST-003',
      site_brief: 'SB-001',
      variant: 'optimal',
      origin: 'ai_primary',
      status: 'Approved',
      reviewed_by: 'engineer@riad.fun',
      reviewed_at: '2026-06-25T10:00:00',
      ai_result: null,
      total_cost: 150000,
      total_margin: 30000,
      items: [],
    })

    render(<EstimateDetailPage />)
    await waitFor(() => {
      expect(screen.getByText('Підтвердити → Quotation')).toBeTruthy()
    })

    fireEvent.click(screen.getByText('Підтвердити → Quotation'))
    await waitFor(() => {
      expect(mockedConfirmEstimate).toHaveBeenCalledWith('AI-EST-001')
    })
  })
})
