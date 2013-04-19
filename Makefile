

all: build

clean:
	@rm -rf index.js bin/weathernaut

build: index.js bin/weathernaut

index.js: src/index.coffee
	@coffee -c -o ./ ./src/index.coffee

bin/weathernaut: src/weathernaut.coffee
	@coffee -c -o ./bin/ ./src/weathernaut.coffee
	@echo '#!/usr/bin/env node\n\n' > ./bin/weathernaut
	@cat ./bin/weathernaut.js >> ./bin/weathernaut
	@rm -rf ./bin/weathernaut.js
	@chmod +x bin/weathernaut
