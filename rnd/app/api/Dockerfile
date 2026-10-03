FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

RUN npm install --omit=dev --no-audit --no-fund express

COPY server.js .

# The official node images ship an unprivileged "node" user (uid 1000).
USER node

EXPOSE 4000
CMD ["node", "server.js"]
