FROM node:14 AS dependencies

RUN curl -o- -L https://yarnpkg.com/install.sh | bash
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY package.json yarn.lock ./
RUN $HOME/.yarn/bin/yarn global add serve
RUN $HOME/.yarn/bin/yarn install --pure-lockfile --prod

FROM node:14-slim AS production
USER node
WORKDIR /usr/src/app

EXPOSE 8080
CMD []
# Don't use npm start, see https://github.com/npm/npm/issues/4603
ENTRYPOINT ["serve", "build/"]

COPY app.yaml enterprise_license.pem package.json service_account_key.json ./
COPY --from=dependencies --chown=root:root /usr/src/app/node_modules ./node_modules
COPY build/* ./build/
