"use strict";

// ─── Dependencies ────────────────────────────────────────────────────────────
require("dotenv").config();
const express = require("express");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");
const axios = require("axios");

// ─── App Initialisation ──────────────────────────────────────────────────────
const app = express();
const PORT = process.env.PORT || 3000;
const SERVICE_NAME = "Joke Generator API";

// ─── Middleware ───────────────────────────────────────────────────────────────

// Parse incoming JSON bodies
app.use(express.json());

// HTTP request logger (combined format in production, dev format otherwise)
app.use(morgan(process.env.NODE_ENV === "production" ? "combined" : "dev"));

// Rate limiter: max 30 requests per minute per IP
const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute window
  max: 30,             // limit each IP to 30 requests per window
  skip: () => process.env.NODE_ENV === "test",
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: "Too many requests. Please slow down and try again in a minute.",
  },
});
app.use(limiter);

// ─── Routes ───────────────────────────────────────────────────────────────────

// Serve static files from public directory
app.use(express.static("public"));

app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    service: SERVICE_NAME,
    uptime: parseFloat(process.uptime().toFixed(2)), // seconds, rounded to 2dp
  });
});

app.get("/joke", async (req, res, next) => {
  try {
    const { category = "Any", blacklistFlags, type } = req.query;

    // Construct the JokeAPI URL with parameters
    let apiUrl = `https://v2.jokeapi.dev/joke/${category}`;
    const params = new URLSearchParams();

    if (blacklistFlags) {
      params.append("blacklistFlags", blacklistFlags);
    }
    if (type) {
      params.append("type", type);
    }

    const queryString = params.toString();
    if (queryString) {
      apiUrl += `?${queryString}`;
    }

    const response = await axios.get(apiUrl, {
      timeout: 5000, // 5-second timeout so we don't hang forever
    });

    const data = response.data;

    if (data.error) {
      return res.status(400).json({ error: data.message || "Failed to fetch joke." });
    }

    // Normalise the upstream response into a clean shape
    const joke =
      data.type === "single"
        ? { type: "single", category: data.category, joke: data.joke }
        : {
            type: "twopart",
            category: data.category,
            setup: data.setup,
            delivery: data.delivery,
          };

    res.json(joke);
  } catch (err) {
    // If the upstream request failed, wrap it in a 502
    if (err.response || err.request || err.isAxiosError) {
      const upstreamError = new Error(
        "Failed to fetch joke from upstream service. Please try again later."
      );
      upstreamError.status = 502;
      return next(upstreamError);
    }
    next(err); // Pass any other unexpected errors to the global handler
  }
});

// ─── 404 Handler ─────────────────────────────────────────────────────────────
// Catches requests that don't match any defined route
app.use((req, res) => {
  res.status(404).json({
    error: `Route ${req.method} ${req.path} not found.`,
  });
});

// Global Error Handler ────────────────────────────────────────────────────
// Must have four parameters so Express recognises it as an error handler
app.use((err, req, res, next) => {
  const status = err.status || 500;
  const message =
    status === 500 ? "An unexpected internal server error occurred." : err.message;

  // Log the full error server-side (avoid leaking stack traces to the client)
  if (status === 500) {
    console.error("[ERROR]", err);
  }

  res.status(status).json({ error: message });
});

// ─── Start Server ────────────────────────────────────────────────────────────
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`✅  ${SERVICE_NAME} is running on http://localhost:${PORT}`);
  });
}

module.exports = app; // Export for testing
