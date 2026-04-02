# Use Node.js 20 on Alpine for a small, secure base
FROM node:20-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy dependency manifests
COPY package*.json ./

# Install ONLY production dependencies (omit devDependencies like Jest)
RUN npm ci --omit=dev

# ─── Final Production Image ───────────────────────────────────────────────────
FROM node:20-alpine

# Use production environment by default
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
ENV PORT=3000

WORKDIR /app

# Install security updates and tini (for better signal handling as PID 1)
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache tini

# Copy only the necessary files from the local directory
# (Respects .dockerignore to keep the image slim)
COPY . .

# Copy production node_modules from the builder stage
COPY --from=builder /app/node_modules ./node_modules

# Ensure the app files are owned by the non-privileged 'node' user
RUN chown -R node:node /app

# Run the container as the 'node' user for security
USER node

# Expose the port the app listens on
EXPOSE ${PORT}

# Add a health check to monitor the container's status
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://localhost:${PORT}/health').then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))"

# Use tini as the entrypoint to handle signals properly
ENTRYPOINT ["/sbin/tini", "--"]

# Start the application
CMD ["node", "app.js"]
