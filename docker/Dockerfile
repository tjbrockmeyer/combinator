FROM codesimple/elm:0.19 as build
WORKDIR /app
COPY elm.json .
RUN mkdir src && \
    printf "module Main exposing (..)\nx = 1\n" > src/Main.elm && \
    elm make --output /dev/null src/Main.elm && \
    touch src/Main.elm
COPY src src
RUN elm make --output public/combinator/index.html src/Main.elm

FROM nginx as prod
COPY --from=build --chown=nginx:nginx /app/public /usr/share/nginx/html
COPY --chown=nginx:nginx public/combinator/data /usr/share/nginx/html/combinator/data
