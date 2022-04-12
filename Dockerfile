FROM node:16-alpine@sha256:38bc06c682ae1f89f4c06a5f40f7a07ae438ca437a2a04cf773e66960b2d75bc
ENV NODE_ENV production
WORKDIR /usr/src/app
COPY --chown=node:node . /usr/src/app
RUN npm ci --only=production
USER node
CMD "npm" "start"
