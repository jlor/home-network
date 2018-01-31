# Theme setup
```
git clone https://github.com/schemar/solarc-theme.git ~/Documents/solarc-theme.git
cd ~/Documents/solarc-theme
sudo apt install libgtk-3-dev
./autogen.sh --prefix=/usr
sudo make install
```
Set SolArc-Dark using gnome-tweak-tool

# Vim pathogen setup
```
sudo apt install vim vim-gtk3
mkdir -p ~/.vim/autoload ~/.vim/bundle && \
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
```
# Vim theme setup
```
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
cat << EOF > ~/.vim_runtime/my_configs.vim
syntax enable
set background=dark
let g:solarized_termtrans = 1
colorscheme solarized
EOF
```
