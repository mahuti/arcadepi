cd ~
mkdir build
cd ~/build
mkdir sfml-build

git clone --depth 1 https://github.com/oomek/sfml-pi sfml-pi
cd ~/build/sfml-build

cmake ../sfml-pi -DSFML_DRM=1 -DCMAKE_CXX_FLAGS="-w -Wno-psabi -Wno-deprecated -Wno-deprecated-declarations -Wno-narrowing"
make -j5
sudo make install
sudo ldconfig

cd ~/build
git clone --depth 1 https://github.com/oomek/attract attract
cd ~/build/attract
make -j5 USE_DRM=1 USE_MMAL=1 EXTRA_CFLAGS="-w -Wno-psabi -Wno-deprecated -Wno-deprecated-declarations -Wno-narrowing"
sudo make install USE_DRM=1 USE_MMAL=1
cd ~
rm -rf ~/build
