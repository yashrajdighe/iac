FROM node:20-bookworm-slim AS build
WORKDIR /workspace

COPY services/package.json services/tsconfig.base.json ./
COPY services/lib ./lib
COPY services/runner-binaries-syncer ./runner-binaries-syncer

RUN npm install --workspaces --include-workspace-root
RUN npm run build --workspace @github-runner-gcp/lib
RUN npm run build --workspace @github-runner-gcp/runner-binaries-syncer
RUN npm prune --omit=dev --workspaces --include-workspace-root

FROM gcr.io/distroless/nodejs20-debian12:nonroot
WORKDIR /workspace

COPY --from=build /workspace/node_modules ./node_modules
COPY --from=build /workspace/lib/dist ./node_modules/@github-runner-gcp/lib/dist
COPY --from=build /workspace/lib/package.json ./node_modules/@github-runner-gcp/lib/package.json
COPY --from=build /workspace/runner-binaries-syncer/dist ./dist
COPY --from=build /workspace/runner-binaries-syncer/package.json ./package.json

USER nonroot
ENV NODE_ENV=production
EXPOSE 8080
CMD ["dist/index.js"]
