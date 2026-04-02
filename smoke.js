/**
 * Simple Smoke Test
 * 
 * This script verifies that the API is up and responding correctly to basic requests.
 * It expects the API to be running at the URL provided via the BASE_URL 
 * environment variable (defaults to http://localhost:3000).
 */

const axios = require('axios');

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';

const checkEndpoint = async (path, expectedStatus = 200) => {
  const url = `${BASE_URL}${path}`;
  console.log(`🔍 Checking ${url} ...`);
  try {
    const response = await axios.get(url, { timeout: 5000 });
    if (response.status === expectedStatus) {
      console.log(`✅ ${path} returned ${response.status}`);
      return response.data;
    } else {
      console.error(`❌ ${path} returned ${response.status}, expected ${expectedStatus}`);
      process.exit(1);
    }
  } catch (error) {
    console.error(`❌ Failed to reach ${url}: ${error.message}`);
    process.exit(1);
  }
};

async function runSmokeTest() {
  console.log('🚀 Starting Smoke Test...\n');

  // 1. Check Root
  const rootData = await checkEndpoint('/');
  if (!rootData.message || !rootData.message.includes('Joke Generator API')) {
    console.error('❌ Root response missing welcome message');
    process.exit(1);
  }

  // 2. Check Health
  const healthData = await checkEndpoint('/health');
  if (healthData.status !== 'ok') {
    console.error('❌ Health status not ok');
    process.exit(1);
  }

  // 3. Check Joke
  // Note: This verifies our logic and connection to upstream (or our mock if running in a test env)
  await checkEndpoint('/joke');

  console.log('\n✨ Smoke Test Passed Successfully!');
}

runSmokeTest();
