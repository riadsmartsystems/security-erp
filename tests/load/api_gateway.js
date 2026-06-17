import http from "k6/http";
import { check, sleep } from "k6";
import { Rate } from "k6/metrics";

const errorRate = new Rate("errors");

const BASE_URL = __ENV.BASE_URL || "http://localhost:8000";
const TEST_USER = __ENV.TEST_USER || "testuser";
const TEST_PASS = __ENV.TEST_PASS || "testpass";

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
    BASE_URL + "/api/v1/auth/login",
    JSON.stringify({ username: TEST_USER, password: TEST_PASS }),
    { headers: { "Content-Type": "application/json" } }
  );

  if (loginRes.status === 200) {
    const body = JSON.parse(loginRes.body);
    return { token: body.access_token || body.token };
  }
  return { token: "" };
}

export default function (data) {
  var authHeaders = { "Content-Type": "application/json" };
  if (data.token) {
    authHeaders["Authorization"] = "Bearer " + data.token;
  }

  var endpoints = [
    { url: "/health", name: "Health", threshold: 200 },
    { url: "/api/v1/auth/me", name: "Auth_Me", threshold: 300 },
    { url: "/api/v1/tickets", name: "Tickets", threshold: 500 },
    { url: "/api/v1/objects", name: "Objects", threshold: 500 },
    { url: "/api/v1/equipment", name: "Equipment", threshold: 500 },
  ];

  for (var i = 0; i < endpoints.length; i++) {
    var ep = endpoints[i];
    var res = http.get(BASE_URL + ep.url, { headers: authHeaders });

    var ok = check(res, {
      [ep.name + " status OK"]: function (r) { return r.status === 200 || r.status === 401; },
      [ep.name + " fast"]: function (r) { return r.timings.duration < ep.threshold; },
    });

    errorRate.add(res.status >= 500);
  }

  sleep(1);
}

export function handleSummary(data) {
  return {
    "/home/joker/RIAD CRM/tests/load/results.json": JSON.stringify(data, null, 2),
    stdout: textSummary(data),
  };
}

function textSummary(data) {
  var reqs = data.metrics.http_reqs ? data.metrics.http_reqs.values.count : 0;
  var avg = data.metrics.http_req_duration ? data.metrics.http_req_duration.values.avg.toFixed(2) : 0;
  var p95 = data.metrics.http_req_duration ? data.metrics.http_req_duration.values["p(95)"].toFixed(2) : 0;
  var errRate = data.metrics.errors ? (data.metrics.errors.values.rate * 100).toFixed(2) : 0;

  return "\n=== Load Test Results ===\n" +
    "  Requests: " + reqs + "\n" +
    "  Avg: " + avg + "ms\n" +
    "  P95: " + p95 + "ms\n" +
    "  Errors: " + errRate + "%\n";
}
