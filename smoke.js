const axios = require("axios");

const BASE_URL = process.env.BASE_URL || "http://localhost:3000";
axios.defaults.timeout = 5000;

let hasError = false;

// ⏳ sleep helper
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// 🔁 retry wrapper (important for CI startup delay)
const retry = async (fn, retries = 5, delay = 2000) => {
  while (retries--) {
    try {
      return await fn();
    } catch (err) {
      if (retries === 0) throw err;
      console.log("⏳ Retrying...");
      await sleep(delay);
    }
  }
};

// 🔍 endpoint checker
const checkEndpoint = async (path, expectedStatus = 200) => {
  const url = `${BASE_URL}${path}`;
  console.log(`🔍 Checking ${url} ...`);

  try {
    const response = await axios.get(url);

    if (response.status === expectedStatus) {
      console.log(`✅ ${path} returned ${response.status}`);
      return response.data;
    } else {
      console.error(
        `❌ ${path} returned ${response.status}, expected ${expectedStatus}`,
      );
      hasError = true;
    }
  } catch (error) {
    console.error(`❌ Failed to reach ${url}: ${error.message}`);
    hasError = true;
    throw error; // important for retry
  }
};

// 🚀 main runner
async function runSmokeTest() {
  console.log("🚀 Starting Smoke Test...\n");

  try {
    // 1. Health check FIRST (fail fast)
    const healthData = await retry(() => checkEndpoint("/health"));
    if (!healthData || healthData.status !== "ok") {
      console.error("❌ Health check failed");
      hasError = true;
    }

    // 2. Root endpoint
    const rootData = await retry(() => checkEndpoint("/"));
    if (
      !rootData ||
      typeof rootData !== "string" ||
      !rootData.includes("Joke Generator")
    ) {
      console.error("❌ Root response invalid");
      hasError = true;
    }

    // 3. Business endpoint
    await retry(() => checkEndpoint("/joke"));
  } catch (err) {
    console.error("❌ Smoke test encountered fatal error");
    hasError = true;
  }

  // ✅ Final result
  if (hasError) {
    console.error("\n❌ Smoke Test FAILED");
    process.exit(1);
  }

  console.log("\n✨ Smoke Test PASSED");
  process.exit(0);
}

runSmokeTest();
