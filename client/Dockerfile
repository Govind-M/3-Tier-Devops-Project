# Stage 1 : Build React App
FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./

# Clean and fast install using lock file (CI-style)
RUN npm ci

COPY . .

# Build the react app (generates static files in /build)
RUN npm build

# Stage 2 : Serve with Nginx
FROM nginx:alpine

COPY --from=builder /app/build /usr/share/nginx/html

# Add custom nginx config (optional but usually required for SPA )
COPY nginx/default.cong /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx","-g","daemon off;"]