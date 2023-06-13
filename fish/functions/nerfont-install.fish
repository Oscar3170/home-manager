function nerdfont-install
	set TMP_DIR (mktemp -d --suffix="nerdfont-installer")
	cd $TMP_DIR
	git clone https://github.com/ryanoasis/nerd-fonts.git --depth 1
	cd nerd-fonts
	./install.sh "DejaVuSansMono"
end

