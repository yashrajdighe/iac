################################
# Build stage
################################
FROM node:20-bookworm-slim AS build
WORKDIR /workspace

COPY services/package.json services/tsconfig.base.json ./
COPY services/lib ./lib
COPY services/webhook ./webhook

RUN npm install --workspaces --include-workspace-root
RUN npm run build --workspace @github-runner-gcp/lib
RUN npm run build --workspace @github-runner-gcp/webhook
RUN npm prune --omit=dev --workspaces --include-workspace-root

################################
# Runtime stage
################################
FROM gcr.io/distroless/nodejs20-debian12:nonroot
WORKDIR /workspace

COPY --from=build /workspace/node_modules ./node_modules
COPY --from=build /workspace/lib/dist ./node_modules/@github-runner-gcp/lib/dist
COPY --from=build /workspace/lib/package.json ./node_modules/@github-runner-gcp/lib/package.json
COPY --from=build /workspace/webhook/dist ./dist
COPY --from=build /workspace/webhook/package.json ./package.json

USER nonroot
ENV NODE_ENV=production
EXPOSE 8080
CMD ["dist/index.js"]
