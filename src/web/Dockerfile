### STAGE 1: BUILD ###
FROM node:22-alpine AS builder
WORKDIR /usr/src/app
COPY . .
RUN npm install --legacy-peer-deps
RUN npm install postcss@8.4.31 --save-dev --legacy-peer-deps
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN npm run build -- --prod

### STAGE 2: RUN ###
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /usr/src/app/dist/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]