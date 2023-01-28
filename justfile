build:
    elm make --output public/combinator/index.html src/Main.elm

run:
    elm-live -d public -p 8081 src/Main.elm -- --output public/combinator/index.html

docker-run:
    sudo docker compose -p combinator -f docker/compose.test.yml build
    sleep 1 && open http://localhost:8080/combinator/ &
    sudo docker compose -p combinator -f docker/compose.test.yml up
