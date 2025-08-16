# Stage 1 : Build React App
FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./

# Clean and fast install using lock file (CI-style)
# RUN npm ci

RUN npm install

COPY . .

# Optional: pass REACT_APP_API as build arg
ARG REACT_APP_API
ENV REACT_APP_API=$REACT_APP_API

# Build the react app (generates static files in /build)
RUN npm build

# Stage 2 : Serve with Nginx
FROM nginx:alpine

COPY --from=builder /app/build /usr/share/nginx/html

# Add custom nginx config (optional but usually required for SPA )
COPY default.conf /etc/nginx/conf.d/default.conf

#  Prevent directory listings and ensure correct permissions
RUN chmod -R 755 /usr/share/nginx/html

EXPOSE 80

CMD ["nginx","-g","daemon off;"]