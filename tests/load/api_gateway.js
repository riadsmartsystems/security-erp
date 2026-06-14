import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

const errorRate = new Rate("errors");

const BASE_URL = __ENV.BASE_URL || "http://localhost:8000";
const TOKEN = __ENV.TOKEN || "";

const headers = {
  "Content-Type": "application/json",
  ...(TOKEN && { Authorization: `Bearer ${TOKEN}` }),
};

export const options = {
  stages: [
    { duration: "30s", target: 5 },
    { duration: "1m", target: 10 },
    { duration: "30s", target: 0 },
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"],
    errors: ["rate<0.1"],
  },
};

export function setup() {
  const loginRes = http.post(
    `${BASE_URL}/api/v1/auth/login`,
    JSON.stringify({ username: "joker", password: "jokerLA23" }),
    { headers: { "Content-Type": "application/json" } }
  );

  if (loginRes.status === 200) {
    const body = JSON.parse(loginRes.body);
    return { token: body.access_token || body.token };
  }
  return { token: "" };
}

export default function (data) {
  const authHeaders = {
    ...headers,
    ...(data.token && { Authorization: `Bearer ${data.token}` }),
  };

  const endpoints = [
    { url: "/health", name: "Health", threshold: 200 },
    { url: "/api/v1/auth/me", name: "Auth/Me", threshold: 300 },
    { url: "/api/v1/tickets", name: "Tickets List", threshold: 500 },
    { url: "/api/v1/objects", name: "Objects List", threshold: 500 },
    { url: "/api/v1/equipment", name: "Equipment List", threshold: 500 },
  ];

  for (const ep of endpoints) {
    const res = http.get(`${BASE_URL}${ep.url}`, { headers: authHeaders });

    check(res, {
      [`${ep.name} - status OK`]: (r) => r.status === 200 || r.status === 401,
      [`${ep.name} - latency < ${ep.threshold}ms`]: (r) =>
        r.timings.duration < ep.threshold,
    });

    errorRate.add(res.status >= 500);
  }

  sleep(2);
}

export function handleSummary(data) {
  return {
    "/home/joker/RIAD CRM/tests/load/results.json": JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: " ", enableColors: true }),
  };
}

function textSummary(data, opts) {
  return `
=== Load Test Results ===
  Requests: ${data.metrics.http_reqs?.values?.count || 0}
  Duration: ${data.metrics.http_req_duration?.values?.avg?.toFixed(2) || 0}ms avg
  P95: ${data.metrics.http_req_duration?.values?.["p(95)"]?.toFixed(2) || 0}ms
  Errors: ${((data.metrics.errors?.values?.rate || 0) * 100).toFixed(2)}%
`;
}
