INSTALL_DIR=~/.local/bin/qr8.sh
SOURCE_DIR=qr8.sh

all:
	@echo "Please run 'make install'"

install:
	@echo ""
	@echo "Installing QR8"

	cp $(SOURCE_DIR) $(INSTALL_DIR)
	
	echo "# QR8             #" >> ~/.bashrc
	
	echo "alias qr8=\". $(INSTALL_DIR)\"" >> ~/.bashrc

	echo "# QR8 END #" >> ~/.bashrc
	
	exec bash
	@echo ''
	@echo 'USAGE:'
	@echo '------'

reinstall:
	make uninstall --no-print-directory
	make install --no-print-directory

uninstall:
	@echo ""
	@echo 'Uninstalling qr8'
	rm -rf $(INSTALL_DIR)
	sed -i '/qr8/ Id' ~/.bashrc

.PHONY: all install
