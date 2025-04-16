FROM ubuntu:22.04

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 安装必要的工具和依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    wget \
    unzip \
    libopenblas-dev \
    liblapack-dev \
    git \
    autoconf \
    automake \
    libtool \
    zlib1g-dev \
    golang-go \
    && rm -rf /var/lib/apt/lists/*

# 设置Go环境变量
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

# 下载并编译CoinUtils
WORKDIR /tmp
RUN wget https://github.com/coin-or/CoinUtils/archive/releases/2.11.9.tar.gz && \
    tar xzf 2.11.9.tar.gz && \
    cd CoinUtils-releases-2.11.9 && \
    ./configure --prefix=/usr/local && \
    make -j4 && \
    make install && \
    cd /tmp && \
    rm -rf CoinUtils-releases-2.11.9 2.11.9.tar.gz

# 下载并编译Osi
RUN wget https://github.com/coin-or/Osi/archive/releases/0.108.8.tar.gz && \
    tar xzf 0.108.8.tar.gz && \
    cd Osi-releases-0.108.8 && \
    ./configure --prefix=/usr/local && \
    make -j4 && \
    make install && \
    cd /tmp && \
    rm -rf Osi-releases-0.108.8 0.108.8.tar.gz

# 下载并编译Clp
RUN wget https://github.com/coin-or/Clp/archive/releases/1.17.8.tar.gz && \
    tar xzf 1.17.8.tar.gz && \
    cd Clp-releases-1.17.8 && \
    ./configure --prefix=/usr/local && \
    make -j4 && \
    make install && \
    cd /tmp && \
    rm -rf Clp-releases-1.17.8 1.17.8.tar.gz

# 下载并编译Cgl
RUN wget https://github.com/coin-or/Cgl/archive/releases/0.60.7.tar.gz && \
    tar xzf 0.60.7.tar.gz && \
    cd Cgl-releases-0.60.7 && \
    ./configure --prefix=/usr/local && \
    make -j4 && \
    make install && \
    cd /tmp && \
    rm -rf Cgl-releases-0.60.7 0.60.7.tar.gz

# 下载并编译CBC
RUN wget https://github.com/coin-or/Cbc/archive/releases/2.10.8.tar.gz && \
    tar xzf 2.10.8.tar.gz && \
    cd Cbc-releases-2.10.8 && \
    ./configure --prefix=/usr/local && \
    make -j4 && \
    make install && \
    cd /tmp && \
    rm -rf Cbc-releases-2.10.8 2.10.8.tar.gz

# 更新动态链接器运行时绑定
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf && \
    ldconfig

# 创建工作目录
WORKDIR /app

# 复制Go源代码
COPY go/ /app/go/

# 编译C++桥接层
RUN cd /app/go/bridge && \
    g++ -c -fPIC cbc_bridge.cpp -o cbc_bridge.o -I/usr/local/include/coin-or && \
    g++ -shared -o libcbc_bridge.so cbc_bridge.o -L/usr/local/lib -lCbcSolver -lCbc -lCgl -lOsiClp -lClp -lOsi -lCoinUtils

# 编译Go程序
RUN cd /app/go && \
    export CGO_ENABLED=1 && \
    export CGO_LDFLAGS="-L/app/go/bridge -lcbc_bridge" && \
    export CGO_CFLAGS="-I/app/go/bridge" && \
    go build -o cbc_go main.go

# 设置容器启动时运行的命令
CMD ["/app/go/cbc_go"]
