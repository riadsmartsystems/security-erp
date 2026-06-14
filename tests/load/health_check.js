import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

const errorRate = new Rate("errors");
const latencyP95 = new Trend("latency_p95");

const BASE_URL = __ENV.BASE_URL || "http://localhost:8000";
const TOKEN = __ENV.TOKEN || "";

const headers = {
  "Content-Type": "application/json",
  ...(TOKEN && { Authorization: `Bearer ${TOKEN}` }),
};

export const options = {
  stages: [
    { duration: "30s", target: 10 },
    { duration: "1m", target: 10 },
    { duration: "30s", target: 0 },
  ],
  thresholds: {
    http_req_duration: ["p(95)<200"],
    errors: ["rate<0.05"],
    latency_p95: ["p(95)<200"],
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/health`, { headers });

  check(res, {
    "status is 200": (r) => r.status === 200,
    "response time < 200ms": (r) => r.timings.duration < 200,
  });

  errorRate.add(res.status !== 200);
  latencyP95.add(res.timings.duration);

  sleep(1);
}
