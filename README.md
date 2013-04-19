
# // weather(or)naut

weather information in the terminal.  data provided by [wunderground.com](http://wunderground.com)'s JSON API.

# install

```shell
$ npm install -g weathernaut
```



# use

astronomical information (i.e., moon phase, sunrise and sunset times):

```shell
$ weathernaut -s astronomy -z [zipcode] -k [your weather underground api key]
```

basic weather forecast:

```shell
$ weathernaut -s forecast -z [zipcode] -k [your weather underground api key] -d [number of days]
```


# hacking + building from source

to build:

```shell
$ make clean && make
```

things to hack:

- in `src/index.coffee`, you'll find three classes: `Weathernaut`, `WeathernautStore`, and `WeathernautDefaultFormatter`.  you get one guess, so eat your wheaties.



# authors / contributors

bryn austin bellomy <<bryn.bellomy@gmail.com>>



# license (WTFPL v2)
 
DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
Version 2, December 2004

Copyright (C) 2004 Sam Hocevar <[sam@hocevar.net](mailto:sam@hocevar.net)>

Everyone is permitted to copy and distribute verbatim or modified 
copies of this license document, and changing it is allowed as long 
as the name is changed. 

## DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHAT THE FUCK YOU WANT TO. 


