###############################################################################
# Build and pin control-plane images.
#
# Required vars:
#   REPO        Artifact Registry path, e.g. asia-south1-docker.pkg.dev/<p>/<r>
#   MODULE_VER  Tag for the immutable release, e.g. 0.1.0
#
# Targets:
#   build      Build all four images locally with Docker.
#   push       Build + push (uses docker buildx push).
#   cloudbuild Trigger the Cloud Build pipeline.
#   digests    Resolve sha256 digests for $MODULE_VER tags from $REPO and
#              print the locals.control_plane_images map ready to paste into
#              main.tf.
###############################################################################

REPO ?=
MODULE_VER ?= 0.1.0
SERVICES := webhook scale-up scale-down runner-binaries-syncer

.PHONY: build push cloudbuild digests check-vars

check-vars:
	@if [ -z "$(REPO)" ]; then echo "REPO=<artifact-registry-path> is required" >&2; exit 1; fi

build: check-vars
	@for svc in $(SERVICES); do \
		echo "==> build $$svc"; \
		docker build -f $$svc/Dockerfile -t $(REPO)/$$svc:$(MODULE_VER) . ; \
	done

push: check-vars
	@for svc in $(SERVICES); do \
		echo "==> push $$svc"; \
		docker push $(REPO)/$$svc:$(MODULE_VER) ; \
	done

cloudbuild: check-vars
	gcloud builds submit \
		--config=cloudbuild.yaml \
		--substitutions=_REPO=$(REPO),_MODULE_VER=$(MODULE_VER) \
		.

digests: check-vars
	@echo "control_plane_images = {"
	@for svc in $(SERVICES); do \
		key=$$(echo $$svc | tr - _) ; \
		digest=$$(gcloud artifacts docker images describe $(REPO)/$$svc:$(MODULE_VER) --format='value(image_summary.digest)') ; \
		echo "  $$key = \"$(REPO)/$$svc@$$digest\"" ; \
	done
	@echo "}"
