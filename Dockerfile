FROM nginx:1.25-alpine

COPY infra-compose/web1 /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost || exit 1
