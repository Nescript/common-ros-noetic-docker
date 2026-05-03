# python解决
# 1. 备份原有的链接（可选）
mv /usr/bin/python3 /usr/bin/python3.8.bak

# 2. 强行链接到 3.10
ln -s /usr/local/bin/python3.10 /usr/bin/python3

# 3. 验证（必须显示 3.10.13）
python3 --version


# 1. 强制覆盖 python 软链接
ln -sf /usr/local/bin/python3.10 /usr/bin/python

# 2. 强制覆盖 python3 软链接（确保万无一失）
ln -sf /usr/local/bin/python3.10 /usr/bin/python3

# 3. 验证两个命令的指向
python --version   # 应显示 3.10.13
python3 --version  # 应显示 3.10.13

# 安装开发依赖
apt install -y libffi-dev libxml2-dev

# 1. 升级 Wayland 核心 (为了得到新版 wayland-scanner)
cd /home/nesc
git clone https://gitlab.freedesktop.org/wayland/wayland.git
cd wayland && mkdir build && cd build
meson setup .. -Dprefix=/usr -Ddocumentation=false
ninja install

# 2. 升级 Wayland Protocols (为了满足 Mesa 26.1 要求)
cd /home/nesc
git clone https://gitlab.freedesktop.org/wayland/wayland-protocols.git
cd wayland-protocols && mkdir build && cd build
meson setup .. -Dprefix=/usr
ninja install

cd /home/nesc/mesa/build
rm -rf *

meson setup .. \
    -Dprefix=/usr \
    -Dplatforms=x11 \
    -Dgallium-drivers=radeonsi,softpipe,llvmpipe \
    -Dvulkan-drivers=[] \
    -Dbuildtype=release \
    -Dllvm=enabled \
    -Dshared-llvm=enabled \
    -Dllvm-config=/usr/lib/llvm-21/bin/llvm-config \
    -Dvideo-codecs=[] \
    -Dwayland=disabled # 暂时关闭 Wayland 避开协议版本冲突


# 使用 ninja 进行多线程编译 (-j 指定核心数，建议留 2 个核心给系统免得卡死)
ninja -C build -j$(($(nproc) - 2))

# 编译完成后安装到系统
ninja -C build install