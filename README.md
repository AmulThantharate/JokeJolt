# 🎭 Joke Generator API

A simple but production-quality REST API built with **Node.js** and **Express** that serves random jokes fetched from [JokeAPI](https://v2.jokeapi.dev).

---

## 🚀 Quick Start

```bash
# 1. Install dependencies
npm install

# 2. (Optional) Create a .env file to customise the port
echo "PORT=3000" > .env

# 3. Start the server
node app.js
```

The server will start at **http://localhost:3000**.

---

## 📡 Endpoints

| Method | Path       | Description                          |
|--------|------------|--------------------------------------|
| GET    | `/`        | Welcome message + docs link          |
| GET    | `/joke`    | Fetch a random joke                  |
| GET    | `/health`  | Health check (status, uptime)        |
| GET    | `/api-docs`| Interactive Swagger UI documentation |

---

## 🔒 Rate Limiting

Each IP address is limited to **30 requests per minute**. Exceeding this returns a `429 Too Many Requests` response.

---

## ⚙️ Environment Variables

| Variable | Default | Description       |
|----------|---------|-------------------|
| `PORT`   | `3000`  | Server listen port |

---

## 🛠 Tech Stack

- **Express** — web framework
- **Axios** — HTTP client for upstream JokeAPI calls
- **Morgan** — HTTP request logging
- **express-rate-limit** — rate limiting
- **swagger-jsdoc** + **swagger-ui-express** — interactive API docs
- **dotenv** — environment variable management
