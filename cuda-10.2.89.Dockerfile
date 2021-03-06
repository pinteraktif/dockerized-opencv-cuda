FROM nvcr.io/nvidia/pytorch:20.03-py3

LABEL maintainer "Wu Assassin <jambang.pisang@gmail.com>"
LABEL org.opencontainers.image.source https://github.com/pinteraktif/dockerized-opencv-cuda

ENV DEBIAN_FRONTEND="noninteractive"
ENV TZ="Etc/UTC"
ENV PATH="/app/ffmpeg/bin${PATH:+:${PATH}}"
ENV PATH="/app/opencv/bin:${PATH}"
ENV PATH="/root/.cargo/bin:${PATH}"
ENV PATH="/usr/lib/llvm-12/bin:${PATH}"
ENV NVCCPARAMS="-O3"

RUN mkdir -p /app/source && \
    mkdir -p /app/ffmpeg && \
    mkdir -p /app/opencv

WORKDIR /app/source
COPY 00-opencv 00-opencv
COPY 01-opencv-contrib 01-opencv-contrib
COPY 02-ffmpeg 02-ffmpeg
COPY 03-nv-codec-headers 03-nv-codec-headers
COPY 04-dav1d 04-dav1d
COPY 05-svt-av1 05-svt-av1

RUN apt update && \
    apt-get install -y --no-install-recommends \
    apt-utils \
    software-properties-common \
    wget && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    add-apt-repository ppa:team-xbmc/ppa -y && \
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-12 main" > /etc/apt/sources.list.d/clang.list && \
    echo "/app/ffmpeg/lib" > /etc/ld.so.conf.d/ffmpeg.conf && \
    echo "/app/opencv/lib" > /etc/ld.so.conf.d/opencv.conf && \
    echo "/usr/lib/llvm-12/lib" > /etc/ld.so.conf.d/llvm.conf

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    ccache \
    checkinstall \
    clang-12 \
    clang-12-doc \
    clang-format-12 \
    clang-tools-12 \
    clangd-12 \
    cmake \
    curl \
    doxygen \
    flake8 \
    gfortran \
    git-core \
    gnu-standards \
    gobjc \
    gobjc++ \
    libaom-dev \
    libass-dev \
    libatlas-base-dev \
    libavcodec-dev \
    libavformat-dev \
    libavresample-dev \
    libc++-12-dev \
    libc++abi-12-dev \
    libclang-12-dev \
    libclang-common-12-dev \
    libclang1-12 \
    libclc-12-dev \
    libdc1394-22 \
    libdc1394-22-dev \
    libdrm-dev \
    libeigen3-dev \
    libelf-dev \
    libfaac-dev \
    libfaac-dev \
    libfdk-aac-dev \
    libfreetype6-dev \
    libfuzzer-12-dev \
    libgdal-dev \
    libgflags-dev \
    libgif-dev \
    libglvnd-dev \
    libgnutls28-dev \
    libgoogle-glog-dev \
    libgphoto2-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev \
    libgtk-3-dev \
    libharfbuzz-dev \
    libhdf5-dev \
    libjack-jackd2-dev \
    libllvm-12-ocaml-dev \
    libllvm12 \
    libmp3lame-dev \
    libnuma-dev \
    libomp-12-dev \
    libopencore-amrnb-dev \
    libopencore-amrwb-dev \
    libopenjp2-7-dev \
    libopus-dev \
    libpng-dev \
    libpng++-dev \
    libprotobuf-dev \
    librsvg2-dev \
    libsasl2-dev \
    libsass-dev \
    libsdl2-dev \
    libssh-dev \
    libssl-dev \
    libswscale-dev \
    libtbb-dev \
    libtesseract-dev \
    libtheora-dev \
    libtiff-opengl \
    libtiff5-dev \
    libtool \
    libunistring-dev \
    libunwind-12-dev \
    libv4l-dev \
    libva-dev \
    libvdpau-dev \
    libvorbis-dev \
    libvpx-dev \
    libwebp-dev \
    libx264-dev \
    libx265-dev \
    libxcb-shm0-dev \
    libxcb-xfixes0-dev \
    libxcb1-dev \
    libxine2-dev \
    libxvidcore-dev \
    libzstd-dev \
    lld-12 \
    lldb-12 \
    llvm-12 \
    llvm-12-dev \
    llvm-12-doc \
    llvm-12-examples \
    llvm-12-runtime \
    make \
    meson \
    musl \
    musl-dev \
    musl-tools \
    nasm \
    ninja-build\
    p7zip-full \
    pkg-config \
    protobuf-compiler \
    texinfo \
    unzip \
    v4l-utils \
    wget \
    x264 \
    yasm \
    zlib1g-dev && \
    ldconfig && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

RUN conda install numpy BeautifulSoup4

### FFmpeg

RUN mkdir /app/source/04-dav1d/build && \
    cd /app/source/04-dav1d/build && \
    meson setup \
    -D enable_tools="false" \
    -D enable_test="false" \
    --default-library="static" .. \
    --prefix="/app/ffmpeg" \
    --libdir="/app/ffmpeg/lib" && \
    ninja && \
    ninja install && \
    ldconfig

RUN mkdir /app/source/05-svt-av1/build && \
    cd /app/source/05-svt-av1/build && \
    cmake -G "Unix Makefiles" \
    -D CMAKE_INSTALL_PREFIX="/app/ffmpeg" \
    -D CMAKE_BUILD_TYPE="Release" \
    -D BUILD_DEC="ON" \
    -D BUILD_SHARED_LIBS="ON" .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN cd /app/source/03-nv-codec-headers && \
    make install && \
    ldconfig

ARG CUDA_ARCH
ENV NVCCPARAMS="${NVCCPARAMS} -gencode arch=compute_${CUDA_ARCH},code=sm_${CUDA_ARCH}"

RUN cd /app/source/02-ffmpeg && \
    PKG_CONFIG_PATH="/app/ffmpeg/lib/pkgconfig" ./configure \
    --bindir="/app/ffmpeg/bin" \
    --disable-debug \
    --enable-cuda-nvcc \
    --enable-gpl \
    --enable-hardcoded-tables \
    --enable-libass \
    --enable-libdav1d \
    --enable-libdrm \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libnpp \
    --enable-libopus \
    --enable-libsvtav1 \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libwebp \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libxvid \
    --enable-nonfree \
    --enable-nvenc \
    --enable-opengl \
    --enable-openssl \
    --enable-vaapi \
    --extra-cflags="-I/app/ffmpeg/include -I/usr/local/cuda/include" \
    --extra-ldflags="-L/app/ffmpeg/lib -L/usr/local/cuda/lib64" \
    --extra-libs="-lpthread -lm" \
    --nvccflags="${NVCCPARAMS}" \
    --prefix="/app/ffmpeg"; \
    tail -50 ffbuild/config.log && \
    make -j$(nproc) && \
    make install && \
    ldconfig

### OpenCV

RUN mkdir /app/source/00-opencv/build && \
    cd /app/source/00-opencv/build && \
    cmake -D CMAKE_BUILD_TYPE="Release" \
    -D BUILD_DOCS="ON" \
    -D BUILD_EXAMPLES="OFF" \
    -D BUILD_NEW_PYTHON_SUPPORT="ON" \ 
    -D BUILD_opencv_cudacodec="ON" \
    -D BUILD_opencv_python2="OFF" \
    -D BUILD_opencv_python3="ON" \
    -D BUILD_opencv_world="ON" \
    -D BUILD_SHARED_LIBS="ON" \
    -D CMAKE_INSTALL_PREFIX="/app/opencv" \
    -D CPU_BASELINE="SSE,SSE2,SSE3,SSSE3,SSE4_1,POPCNT,SSE4_2,AVX,AVX2,FP16" \
    -D CPU_DISPATCH="SSE,SSE2,SSE3,SSSE3,SSE4_1,POPCNT,SSE4_2,AVX,AVX2,FP16" \
    -D CUDA_ARCH_BIN="${CUDA_ARCH}" \
    -D CUDA_ARCH_PTX="${CUDA_ARCH}" \
    -D CUDA_FAST_MATH="ON" \
    -D ENABLE_CCACHE="ON" \
    -D ENABLE_FAST_MATH="ON" \
    -D ENABLE_FLAKE8="ON" \
    -D ENABLE_PYLINT="ON" \
    -D HAVE_opencv_python3="ON" \
    -D INSTALL_C_EXAMPLES="OFF" \
    -D INSTALL_PYTHON_EXAMPLES="OFF" \
    -D OPENCV_DNN_CUDA="ON" \
    -D OPENCV_DNN_OPENCL="ON" \
    -D OPENCV_ENABLE_NONFREE="ON" \
    -D OPENCV_EXTRA_MODULES_PATH="/app/source/01-opencv-contrib/modules" \
    -D OPENCV_GENERATE_PKGCONFIG="ON" \
    -D OPENCV_PC_FILE_NAME="opencv.pc" \
    -D PARALLEL_ENABLE_PLUGINS="ON" \
    -D WITH_CUBLAS="ON" \
    -D WITH_CUDA="ON" \
    -D WITH_CUDNN="ON" \
    -D WITH_CUFFT="ON" \
    -D WITH_FFMPEG="ON" \
    -D WITH_GDAL="ON" \
    -D WITH_GSTREAMER="ON" \
    -D WITH_GTK="ON" \
    -D WITH_ITT="OFF" \
    -D WITH_NVCUVID="ON" \
    -D WITH_OPENGL="ON" \
    -D WITH_QT="OFF" \
    -D WITH_TBB="ON" \
    -D WITH_V4L="ON" \
    .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain stable -y

RUN rustup default 1.55.0 && \
    rustup target add x86_64-unknown-linux-musl && \
    rustup update

RUN rm /opt/conda/lib/python3.6/site-packages/cv2/cv2.cpython-36m-x86_64-linux-gnu.so ; \
    cp /app/opencv/lib/python3.6/site-packages/cv2/python-3.6/cv2.cpython-36m-x86_64-linux-gnu.so \
    /opt/conda/lib/python3.6/site-packages/cv2/cv2.cpython-36m-x86_64-linux-gnu.so && \
    echo "/opt/conda/lib/python3.6/site-packages/cv2" > /etc/ld.so.conf.d/cv2.conf && \
    ldconfig

RUN echo "** Clang **" && clang -v && echo "" && \
    echo "** GCC **" && gcc -v && echo "" && \
    echo "** Python **" && python3 --version && echo "" && \
    echo "** Rust **" && rustc -vV && echo "" && \
    echo "** OpenCV **" && python3 -c "import cv2; print(cv2.getBuildInformation())" && echo "" && \
    echo "** FFmpeg **" && ffmpeg -version && echo "" && \
    echo "** Environments **" && env && echo ""

WORKDIR /app
