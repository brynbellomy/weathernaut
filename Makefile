

all: build

clean:
	@rm index.js bin/weathernaut

build: index.js bin/weathernaut

index.js: src/index.coffee
	@coffee -c src/index.coffee -o ./

bin/weathernaut: src/weathernaut.coffee
	@coffee -c src/weathernaut.coffee ./bin/
	@mv ./bin/weathernaut.js weathernaut
	@chmod +x bin/weathernaut
