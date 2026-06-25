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

export interface EstimateBuildPayload {
  site_brief_name: string
  variant: "budget" | "optimal" | "premium"
}

export interface EstimateBuildResponse {
  name: string
  status: string
  origin: string
}

export interface EstimateData {
  name: string
  site_brief: string | null
  variant: string | null
  origin: string | null
  status: string | null
  reviewed_by: string | null
  reviewed_at: string | null
  ai_result: string | null
  total_cost: number | null
  total_margin: number | null
  items: EstimateItemData[]
}

export interface EstimateItemData {
  name: string
  item_code: string
  item_name: string | null
  qty: number
  unit_price: number | null
  purchase_rate: number | null
  profit: number | null
  margin_pct: number | null
  line_source: string | null
}

export interface EstimateReviewPayload {
  decision: "approved" | "rejected"
}

export interface EstimateConfirmResponse {
  quotation_name: string
}

export async function buildEstimate(payload: EstimateBuildPayload): Promise<EstimateBuildResponse> {
  const { data } = await api.post("/api/v2/estimates/build", payload)
  return data
}

export async function fetchEstimate(name: string): Promise<EstimateData> {
  const { data } = await api.get(`/api/v2/estimates/${name}`)
  return data
}

export async function reviewEstimate(
  name: string,
  payload: EstimateReviewPayload
): Promise<{ name: string; status: string; reviewed_by: string }> {
  const { data } = await api.post(`/api/v2/estimates/${name}/review`, payload)
  return data
}

export async function confirmEstimate(name: string): Promise<EstimateConfirmResponse> {
  const { data } = await api.post(`/api/v2/estimates/${name}/confirm`)
  return data
}

export async function fetchAiDegradation(): Promise<{
  level: string
  providers: string[]
  message: string
}> {
  const { data } = await api.get("/api/v2/ai/degradation")
  return data
}

export interface SiteBriefData {
  name: string
  brief_name: string | null
  object_type: string | null
  area_m2: number | null
  cameras_count: number | null
  camera_type: string | null
  archive_days: number | null
  access_control: number | null
  intercom: number | null
  alarm: number | null
  network_needed: number | null
  power_backup: number | null
  tech_notes: string | null
  source: string | null
}

export async function fetchSiteBrief(name: string): Promise<SiteBriefData> {
  const { data } = await api.get(`/api/resource/Site Brief/${name}`)
  return data.data ?? data
}

export async function listSiteBriefs(): Promise<{ name: string; brief_name: string | null }[]> {
  const { data } = await api.get("/api/resource/Site Brief", {
    params: { fields: '["name","brief_name"]', limit_page_length: 100 },
  })
  return data.data ?? []
}

export interface ScenarioData {
  name: string
  scenario_name: string
  description: string
  items: ScenarioItemData[]
}

export interface ScenarioItemData {
  item_code: string
  item_name: string
  qty: number
  qty_rule: string
  qty_factor: number
  rate: number
  description: string
}

export async function listScenarios(): Promise<ScenarioData[]> {
  const { data } = await api.get("/api/v2/scenarios")
  return data.scenarios || []
}

export async function fetchScenario(name: string): Promise<ScenarioData> {
  const { data } = await api.get(`/api/v2/scenarios/${name}`)
  return data
}

export async function createScenario(payload: Partial<ScenarioData>): Promise<{ name: string }> {
  const { data } = await api.post("/api/v2/scenarios", payload)
  return data
}

export async function updateScenario(name: string, payload: Partial<ScenarioData>): Promise<{ name: string }> {
  const { data } = await api.post("/api/v2/scenarios", { ...payload, name })
  return data
}

export async function deleteScenario(name: string): Promise<{ success: boolean }> {
  const { data } = await api.delete(`/api/v2/scenarios/${name}`)
  return data
}

export interface AIRequestLogEntry {
  name: string
  creation: string
  provider: string | null
  anonymized_payload: string | null
  tokens: number | null
  latency_ms: number | null
  status: string | null
  error_message: string | null
}

export interface AIRequestLogListResponse {
  logs: AIRequestLogEntry[]
  total: number
}

export async function fetchAIRequestLogs(
  page: number,
  pageSize: number = 20
): Promise<AIRequestLogListResponse> {
  const { data } = await api.get("/api/v2/ai-admin/request-logs", {
    params: { page, page_size: pageSize },
  })
  return data
}

export default api
