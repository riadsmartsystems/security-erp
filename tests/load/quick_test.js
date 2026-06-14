import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://localhost:8000";

export const options = {
  vus: 5,
  duration: "30s",
  thresholds: {
    http_req_duration: ["p(95)<200"],
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/health`);

  check(res, {
    "health status 200": (r) => r.status === 200,
    "latency < 200ms": (r) => r.timings.duration < 200,
    "has status field": (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.status === "ok";
      } catch (e) {
        return false;
      }
    },
  });

  sleep(1);
}
