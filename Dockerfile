#*********************************************************************
# Copyright (c) Intel Corporation 2023
# SPDX-License-Identifier: Apache-2.0
#*********************************************************************/
FROM node:20-bullseye-slim@sha256:f54a16be368537403c6f20e6e9cfa400f4b71c71ae9e1e93558b33a08f109db6 as builder
LABEL license='SPDX-License-Identifier: Apache-2.0' \
    copyright='Copyright (c) Intel Corporation 2023'
WORKDIR /usr/src/app
COPY ["tsconfig.json","tsconfig.build.json","package.json", "package-lock.json*", "npm-shrinkwrap.json*", "./"]

# Install dependencies
RUN npm ci

COPY src ./src/

# Transpile TS => JS
RUN npm run build
RUN npm prune --production

# Build the final image from alpine base
FROM alpine:latest@sha256:7144f7bab3d4c2648d7e59409f15ec52a18006a128c733fcff20d3a4a54ba44a
ENV NODE_ENV=production

RUN addgroup -g 1000 node && adduser -u 1000 -G node -s /bin/sh -D node 
RUN apk update && apk add nodejs && rm -rf /var/cache/apk/*

COPY --from=builder  /usr/src/app/dist /app/dist
COPY --from=builder  /usr/src/app/node_modules /app/node_modules
COPY --from=builder  /usr/src/app/package.json /app/package.json

# set the user to non-root
USER node

# Default Ports Used
EXPOSE 3000

CMD ["node", "/app/dist/index.js"]

