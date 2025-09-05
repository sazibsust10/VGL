FROM node:20-alpine AS build
WORKDIR /app
COPY . /app

# Install deps if package.json exists
RUN if [ -f package.json ]; then       corepack enable;       if [ -f pnpm-lock.yaml ]; then pnpm i --frozen-lockfile; else npm ci || npm i; fi;       npm run build || echo "No build script; skipping";     fi

FROM nginx:1.27-alpine AS serve
COPY --from=build /app/dist /usr/share/nginx/html
COPY docker/frontend/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 5173
CMD ["nginx", "-g", "daemon off;"]
