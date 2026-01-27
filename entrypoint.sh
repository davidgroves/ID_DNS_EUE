#!/bin/bash
set -e

# Mark the mounted directory as safe for git
git config --global --add safe.directory /workdir
git config --global --add safe.directory /workdir/.git

# Bootstrap i-d-template if not present
if [ ! -d lib ] || [ ! -f lib/main.mk ]; then
    echo "Bootstrapping i-d-template..."
    git clone --depth 10 https://github.com/martinthomson/i-d-template lib
fi

# Create internal Makefile if needed (for i-d-template)
if [ ! -f .internal-Makefile ]; then
    cat > .internal-Makefile << 'EOF'
LIBDIR := lib
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
	git clone -q --depth 10 -b main https://github.com/martinthomson/i-d-template $(LIBDIR)
EOF
fi

# Run make with the internal Makefile
exec make -f .internal-Makefile "$@"
