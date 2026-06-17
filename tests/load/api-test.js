import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const loginDuration = new Trend('login_duration');
const ticketsDuration = new Trend('tickets_duration');

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';
const TEST_USER = __ENV.TEST_USER || 'testuser';
const TEST_PASS = __ENV.TEST_PASS || 'testpass';

export const options = {
  stages: [
    { duration: '30s', target: 5 },   // Ramp up to 5 users
    { duration: '1m', target: 5 },     // Stay at 5 users
    { duration: '30s', target: 10 },   // Ramp up to 10 users
    { duration: '1m', target: 10 },    // Stay at 10 users
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<500'],  // 95% of requests under 500ms
    'errors': ['rate<0.1'],              // Error rate under 10%
  },
};

export default function () {
  // Login
  const loginStart = Date.now();
  const loginRes = http.post(`${BASE_URL}/api/v1/auth/login`, 
    JSON.stringify({ username: TEST_USER, password: TEST_PASS }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  loginDuration.add(Date.now() - loginStart);

  const loginOk = check(loginRes, {
    'login status 200': (r) => r.status === 200,
    'login has token': (r) => r.json('access_token') !== undefined,
  });

  if (!loginOk) {
    errorRate.add(1);
    return;
  }
  errorRate.add(0);

  const token = loginRes.json('access_token');
  const headers = { 'Authorization': `Bearer ${token}` };

  // Get tickets
  const ticketsStart = Date.now();
  const ticketsRes = http.get(`${BASE_URL}/api/v1/tickets`, { headers });
  ticketsDuration.add(Date.now() - ticketsStart);

  check(ticketsRes, {
    'tickets status 200': (r) => r.status === 200,
    'tickets has data': (r) => r.json('data') !== undefined,
  });

  // Get objects
  const objectsRes = http.get(`${BASE_URL}/api/v1/objects`, { headers });
  check(objectsRes, {
    'objects status 200': (r) => r.status === 200,
  });

  // Get equipment
  const equipRes = http.get(`${BASE_URL}/api/v1/equipment`, { headers });
  check(equipRes, {
    'equipment status 200': (r) => r.status === 200,
  });

  // Health check (no auth)
  const healthRes = http.get(`${BASE_URL}/health`);
  check(healthRes, {
    'health status 200': (r) => r.status === 200,
  });

  sleep(1);
}

export function handleSummary(data) {
  return {
    'tests/load/results.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: '  ', enableColors: true }),
  };
}
