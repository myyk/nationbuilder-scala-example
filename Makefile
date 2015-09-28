
PROJECT_NAME=dashboard_generator_web
CONTAINER_NAME=dashboardgeneratorweb

# Always run docker-compose with the --project-name flag, or you won't be
# able to correctly base off of the main image for a testing image.
COMPOSE=docker-compose --project-name $(CONTAINER_NAME)

# State tracking, to avoid rebuilding the container on every run.
SENTINEL_DIR=.sentinel
SENTINEL_CONTAINER_CREATED=$(SENTINEL_DIR)/.test-container
SENTINEL_CONTAINER_RUNNING=$(SENTINEL_DIR)/.container-up

###############
# Local Image #
###############

$(SENTINEL_CONTAINER_CREATED): docker-compose.yml
	mkdir -p $(@D)
	$(COMPOSE) build
	@# Start the DB right away to help avoid a race condition
	@# $(COMPOSE) up -d db
	@# until docker exec ${CONTAINER_NAME}_db_1 pg_isready; do sleep 1; done
	touch $@

.PHONY: test-container
test-container: ##[local image] Create a container using docker-compose
test-container: $(SENTINEL_CONTAINER_CREATED)

.PHONY: bash
bash: ##[testing] Run your tests
bash: test-container
	$(COMPOSE) run --service-ports --rm app /bin/bash

.PHONY: run
run: ##[testing] Run your app
run: test-container
	$(COMPOSE) run --service-ports --rm app ./activator run

# .PHONY: test
# test: ##[testing] Run your tests
# test: test-container
# 	$(COMPOSE) run --rm app ./activator ~test

# .PHONY: down
# down: ##[running] Stop the app and dependent containers
# down:
# 	$(COMPOSE) stop
# 	rm -f $(SENTINEL_CONTAINER_RUNNING)

###########
# Cleanup #
###########

.PHONY: clean
clean: ##[clean up] Stop your containers and delete sentinel files.
clean: ##[clean up] Will cause your containers to get rebuilt.
clean: down
	rm -rf $(SENTINEL_DIR)


.PHONY: teardown
teardown:: ##[clean up] Stop & delete all containers
teardown::
	$(COMPOSE) kill
	$(COMPOSE) rm -f -v