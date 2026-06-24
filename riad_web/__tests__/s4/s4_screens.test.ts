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

import { fetchMap, addMountPoint, fetchSerials, fetchStock } from '@/lib/api'

const axios = require('axios').default
const apiInstance = axios.create()

beforeEach(() => {
  jest.clearAllMocks()
})

describe('fetchMap', () => {
  it('повертає дані карти з mount_points', async () => {
    apiInstance.get.mockResolvedValue({
      data: {
        name: 'MAP-001',
        map_kind: 'план приміщення',
        mount_points: [
          { point_uuid: 'pt-1', type: 'камера', label: 'Вхід', x: 0.2, y: 0.3 },
        ],
        cable_routes: [],
      },
    })

    const result = await fetchMap('MAP-001')
    expect(result.name).toBe('MAP-001')
    expect(result.mount_points).toHaveLength(1)
    expect(result.mount_points[0].point_uuid).toBe('pt-1')
    expect(apiInstance.get).toHaveBeenCalledWith('/api/v2/maps/MAP-001')
  })
})

describe('addMountPoint', () => {
  it('відправляє дані точки через POST', async () => {
    apiInstance.post.mockResolvedValue({
      data: { point_uuid: 'new-pt-1', status: 'added' },
    })

    const result = await addMountPoint('MAP-001', {
      point_uuid: 'new-pt-1',
      type: 'камера',
      label: 'Тест',
    })
    expect(result.status).toBe('added')
    expect(result.point_uuid).toBe('new-pt-1')
    expect(apiInstance.post).toHaveBeenCalledWith('/api/v2/maps/MAP-001/points', {
      point_uuid: 'new-pt-1',
      type: 'камера',
      label: 'Тест',
    })
  })
})

describe('fetchSerials', () => {
  it('повертає пагіновані серійники', async () => {
    apiInstance.get.mockResolvedValue({
      data: {
        items: [
          { name: 'SN-001', serial_no: 'SN-001', item: 'CAM', item_name: 'Camera', status: 'Available' },
        ],
        total: 1,
        page: 1,
        page_size: 20,
      },
    })

    const result = await fetchSerials('SN', 1)
    expect(result.items).toHaveLength(1)
    expect(result.items[0].serial_no).toBe('SN-001')
    expect(apiInstance.get).toHaveBeenCalledWith('/api/v2/warehouse/serials', { params: { q: 'SN', page: 1 } })
  })
})

describe('fetchStock', () => {
  it('повертає залишки по Items', async () => {
    apiInstance.get.mockResolvedValue({
      data: {
        items: [
          { item_code: 'CAM-IP', item_name: 'IP Camera', qty: 10, warehouse: 'Main' },
        ],
      },
    })

    const result = await fetchStock()
    expect(result.items).toHaveLength(1)
    expect(result.items[0].item_code).toBe('CAM-IP')
    expect(result.items[0].qty).toBe(10)
    expect(apiInstance.get).toHaveBeenCalledWith('/api/v2/warehouse/stock')
  })
})
