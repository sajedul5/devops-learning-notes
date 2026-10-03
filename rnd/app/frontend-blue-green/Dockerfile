FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

RUN npm install --omit=dev --no-audit --no-fund express axios

COPY index.js .

# The official node images ship an unprivileged "node" user (uid 1000).
USER node

EXPOSE 3000
CMD ["node", "index.js"]
