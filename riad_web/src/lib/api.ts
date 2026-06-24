import axios from 'axios'

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'

let accessToken: string | null = null

export function setAccessToken(token: string | null) {
  accessToken = token
}

const api = axios.create({
  baseURL: API_BASE,
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  if (accessToken) {
    config.headers.Authorization = `Bearer ${accessToken}`
  }
  return config
})

export interface MapData {
  name: string
  passport: string | null
  map_kind: string
  base_plan_media: string | null
  approved_by: string | null
  approved_at: string | null
  mount_points: MountPoint[]
  cable_routes: CableRoute[]
}

export interface MountPoint {
  point_uuid: string
  type: string | null
  label: string | null
  geo: string | null
  x: number | null
  y: number | null
  item: string | null
  serial_no: string | null
  status: string | null
  photo: string | null
  note: string | null
}

export interface CableRoute {
  route_uuid: string
  from_point: string | null
  to_point: string | null
  cable_type: string | null
  length_m: number | null
  path: number[][] | null
}

export interface MapPointRequest {
  point_uuid: string
  type?: string
  label?: string
  geo?: string
  x?: number
  y?: number
  item?: string
  serial_no?: string
  status?: string
  photo?: string
  note?: string
}

export interface WarehouseSerial {
  name: string
  serial_no: string
  item: string | null
  item_name: string | null
  status: string | null
  warehouse: string | null
}

export interface WarehouseStockItem {
  item_code: string
  item_name: string | null
  qty: number
  warehouse: string | null
}

export async function fetchMap(name: string): Promise<MapData> {
  const { data } = await api.get(`/api/v2/maps/${name}`)
  return data
}

export async function addMountPoint(mapName: string, point: MapPointRequest): Promise<{ point_uuid: string; status: string }> {
  const { data } = await api.post(`/api/v2/maps/${mapName}/points`, point)
  return data
}

export async function approveMap(mapName: string): Promise<{ name: string; approved_by: string; approved_at: string }> {
  const { data } = await api.post(`/api/v2/maps/${mapName}/approve`)
  return data
}

export async function fetchSerials(q: string = '', page: number = 1): Promise<{ items: WarehouseSerial[]; total: number; page: number; page_size: number }> {
  const { data } = await api.get('/api/v2/warehouse/serials', { params: { q, page } })
  return data
}

export async function fetchStock(): Promise<{ items: WarehouseStockItem[] }> {
  const { data } = await api.get('/api/v2/warehouse/stock')
  return data
}

export async function fetchStockDetail(item: string): Promise<WarehouseStockItem & { serials: WarehouseSerial[] }> {
  const { data } = await api.get(`/api/v2/warehouse/stock/${item}`)
  return data
}

export interface CalcSubmitPayload {
  object_type: string
  area_m2: number
  cameras_count: number
  archive_days: number
  contact_name: string
  contact_phone: string
  contact_email: string
  captcha_token: string
}

export interface CalcSubmitResponse {
  submission_name: string
  estimated_total: number
  matched_scenario: string | null
  status: string
}

export async function submitCalculator(payload: CalcSubmitPayload): Promise<CalcSubmitResponse> {
  const { data } = await api.post('/api/v2/calculator/submit', payload)
  return data
}

export default api
