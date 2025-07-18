# 多阶段构建优化
# 阶段1: 编译阶段
FROM elixir:1.16-alpine AS build

# 安装构建依赖
RUN apk add --no-cache build-base git python3 curl bash openssl-dev

# 设置工作目录
WORKDIR /app

# 设置构建环境
ENV MIX_ENV=prod

# 安装 hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# 复制依赖文件
COPY mix.exs mix.lock ./
COPY config config

# 获取依赖
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# 复制源代码
COPY priv priv
COPY lib lib

# 编译项目
RUN mix compile

# 阶段2: 构建前端资源
FROM node:20-alpine AS assets

WORKDIR /app

# 复制前端文件
COPY assets/package.json assets/package-lock.json ./assets/
COPY webapps/package.json webapps/package-lock.json ./webapps/

# 安装前端依赖
RUN cd assets && npm ci --progress=false --no-audit --loglevel=error
RUN cd webapps && npm ci --progress=false --no-audit --loglevel=error

# 复制前端源代码
COPY assets ./assets
COPY webapps ./webapps

# 复制编译后的后端代码（需要用于 assets 构建）
COPY --from=build /app ./

# 构建前端资源
RUN cd assets && npm run deploy
RUN cd webapps && npm run build

# 阶段3: 发布阶段
FROM build AS release

WORKDIR /app

# 复制构建好的前端资源
COPY --from=assets /app/priv/static ./priv/static
COPY --from=assets /app/webapps/dist ./priv/static/webapps

# 编译资源并创建发布版本
RUN mix phx.digest
RUN mix release

# 阶段4: 运行时镜像
FROM alpine:3.19 AS runtime

# 安装运行时依赖
RUN apk add --no-cache openssl ncurses-libs libstdc++ libgcc

# 创建应用用户
RUN addgroup -g 1000 -S policr && \
    adduser -u 1000 -S policr -G policr

# 设置工作目录
WORKDIR /app

# 复制发布文件
COPY --from=release --chown=policr:policr /app/_build/prod/rel/policr_mini ./

# 切换到应用用户
USER policr

# 暴露端口
EXPOSE 4000

# 设置环境变量
ENV HOME=/app \
    PORT=4000 \
    MIX_ENV=prod

# 启动命令
CMD ["bin/policr_mini", "start"]