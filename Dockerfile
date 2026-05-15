FROM ruby:3.4.4-slim

# Dependências do sistema
RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  curl \
  libpq-dev \
  libvips-dev \
  imagemagick \
  libssl-dev \
  pkg-config \
  && rm -rf /var/lib/apt/lists/*

# Node.js 20 + pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y nodejs \
  && npm install -g pnpm

WORKDIR /app

# Gems (camada cacheada)
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' \
  && bundle install --jobs 4 --retry 3

# JS dependencies (camada cacheada)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Código da aplicação
COPY . .

# Build do frontend + assets
RUN NODE_OPTIONS="--max-old-space-size=4096" \
    SECRET_KEY_BASE=precompile_placeholder \
    RAILS_ENV=production \
    NODE_ENV=production \
    bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
