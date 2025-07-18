#!/bin/bash
# Docker 构建脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函数：打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_message $RED "错误: $1 未安装"
        exit 1
    fi
}

# 检查必需命令
check_command docker
check_command docker-compose

# 获取版本号
VERSION=${VERSION:-latest}
REGISTRY=${REGISTRY:-}

# 构建镜像名称
if [ -n "$REGISTRY" ]; then
    IMAGE_NAME="$REGISTRY/policr-mini:$VERSION"
else
    IMAGE_NAME="policr-mini:$VERSION"
fi

print_message $YELLOW "开始构建 Docker 镜像..."
print_message $GREEN "镜像名称: $IMAGE_NAME"

# 构建镜像
docker build \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --cache-from $IMAGE_NAME \
    -t $IMAGE_NAME \
    -f Dockerfile \
    .

if [ $? -eq 0 ]; then
    print_message $GREEN "✓ 镜像构建成功！"
    
    # 显示镜像信息
    docker images | grep -E "(REPOSITORY|$IMAGE_NAME)"
    
    # 如果指定了 Registry，推送镜像
    if [ -n "$REGISTRY" ]; then
        print_message $YELLOW "推送镜像到 Registry..."
        docker push $IMAGE_NAME
        
        if [ $? -eq 0 ]; then
            print_message $GREEN "✓ 镜像推送成功！"
        else
            print_message $RED "✗ 镜像推送失败"
            exit 1
        fi
    fi
else
    print_message $RED "✗ 镜像构建失败"
    exit 1
fi

# 构建多架构镜像（可选）
if [ "$BUILD_MULTIARCH" = "true" ]; then
    print_message $YELLOW "构建多架构镜像..."
    
    # 创建并使用新的构建器
    docker buildx create --use --name multiarch-builder || true
    
    # 构建并推送多架构镜像
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --cache-from $IMAGE_NAME \
        -t $IMAGE_NAME \
        -f Dockerfile \
        --push \
        .
    
    if [ $? -eq 0 ]; then
        print_message $GREEN "✓ 多架构镜像构建成功！"
    else
        print_message $RED "✗ 多架构镜像构建失败"
        exit 1
    fi
fi

print_message $GREEN "构建完成！"