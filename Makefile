M_GCC_PINFO_TMPDIR=tmp_gcc
M_EXTDIR=tmp_ext


#==================================
# Create patched gcc-pinfo compiler
#==================================
#GCC-PINFO-VERSION?=4.2.1
GCC-PINFO-VERSION?=4.4.7
#GCC-PINFO-VERSION?=4.4.7-ubuntu
#GCC-PINFO-VERSION?=4.9.2
GCC-PINFO-SINGLE-4.9.2=1
ifeq ($(GCC-PINFO-SINGLE-$(GCC-PINFO-VERSION)),1)
DOWNLOAD_GCC-$(GCC-PINFO-VERSION)=gcc-$(GCC-PINFO-VERSION).tar.bz2
else
DOWNLOAD_GCC-$(GCC-PINFO-VERSION)=gcc-core-$(GCC-PINFO-VERSION).tar.bz2
DOWNLOAD_G++-$(GCC-PINFO-VERSION)=gcc-g++-$(GCC-PINFO-VERSION).tar.bz2
endif



DOWNLOAD_BASE=ftp://ftp.gnu.org/gnu/gcc/gcc-$(GCC-PINFO-VERSION)
GCC_DIFF_CUR=$(CURDIR)/gcc-$(GCC-PINFO-VERSION).diff
GCC_DIFF_NEXT=$(CURDIR)/gcc-$(GCC-PINFO-VERSION)-next.diff
LIBCPP_DIFF_CUR=$(CURDIR)/libcpp-$(GCC-PINFO-VERSION).diff
LIBCPP_DIFF_NEXT=$(CURDIR)/libcpp-$(GCC-PINFO-VERSION)-next.diff

gcc-pinfo: gcc-pinfo-prepare \
	gcc-pinfo-clean \
	gcc-pinfo-configure \
	gcc-pinfo-compile \
	gcc-pinfo-install

gcc-pinfo-prepare:
	-mkdir -p $(M_EXTDIR)
	cd $(M_EXTDIR); if [ ! -f $(DOWNLOAD_GCC-$(GCC-PINFO-VERSION)) ]; then wget $(DOWNLOAD_BASE)/$(DOWNLOAD_GCC-$(GCC-PINFO-VERSION)); wget $(DOWNLOAD_BASE)/$(DOWNLOAD_G++-$(GCC-PINFO-VERSION)); fi
	if [ ! -d $(M_GCC_PINFO_TMPDIR) ]; then mkdir $(M_GCC_PINFO_TMPDIR); fi
	if [ -d $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION) ]; then rm -rf $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION); fi
	if [ -d $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION).ori ]; then rm -rf $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION).ori; fi
	if [ -d $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION)-build ]; then rm -rf $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION)-build; fi
	-cd $(M_GCC_PINFO_TMPDIR); tar xvf $(CURDIR)/$(M_EXTDIR)/$(DOWNLOAD_GCC-$(GCC-PINFO-VERSION));  	tar xvf $(CURDIR)/$(M_EXTDIR)/$(DOWNLOAD_G++-$(GCC-PINFO-VERSION));
	$(if $(GHDL-GCC-$(GCC-PINFO-VERSION)) ,cd $(M_GCC_PINFO_TMPDIR); tar xvf $(CURDIR)/$(M_EXTDIR)/$(DOWNLOAD_GHDL); cp -r $(DOWNLOAD_GHDL_VERSION)/vhdl gcc-$(GCC-PINFO-VERSION)/gcc/; )
	cd $(M_GCC_PINFO_TMPDIR); cp -r gcc-$(GCC-PINFO-VERSION) gcc-$(GCC-PINFO-VERSION).ori; \
	find gcc-$(GCC-PINFO-VERSION).ori/gcc -type f    > gcc-$(GCC-PINFO-VERSION).ori.gcc.filelist; \
	find gcc-$(GCC-PINFO-VERSION).ori/libcpp -type f > gcc-$(GCC-PINFO-VERSION).ori.libcpp.filelist;
	cd $(M_GCC_PINFO_TMPDIR); \
	if [ -f $(GCC_DIFF_CUR) ]; then \
		cat $(GCC_DIFF_CUR) | patch -p1 -d gcc-$(GCC-PINFO-VERSION); \
	fi; \
	if [ -f $(LIBCPP_DIFF_CUR) ]; then \
		cat $(LIBCPP_DIFF_CUR) | patch -p1 -d gcc-$(GCC-PINFO-VERSION); \
	fi;

gcc-pinfo-clean:
	-rm -rf $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION)-build/*

gcc-pinfo-configure-ex:
	export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu; make gcc-pinfo-configure
gcc-pinfo-compile-ex:
	export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu; make gcc-pinfo-compile
gcc-pinfo-install-ex:
	export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu; make gcc-pinfo-install


# libmpc-dev
EXTRA_CONF_4.9.2= --with-gmp=/usr/lib/x86_64-linux-gnu/ --with-mpfr=/usr/lib/x86_64-linux-gnu/ --with-mpc=/usr/lib/x86_64-linux-gnu/

# ,c++
#	--with-sysroot=/ 
gcc-pinfo-configure:
	-mkdir $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION)-build
	cd $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION)-build; ../gcc-$(GCC-PINFO-VERSION)/configure \
        --prefix=/opt/gcc-$(GCC-PINFO-VERSION) --disable-nls --enable-languages=c \
	--target=x86_64-linux-gnu --host=x86_64-linux-gnu --build=x86_64-linux-gnu  \
	--disable-bootstrap --program-suffix=-pinfo --disable-multilib --enable-checking=release  \
        --disable-shared --disable-nls --disable-libstdcxx-pch --disable-libgomp \
	$(EXTRA_CONF_$(GCC-PINFO-VERSION)) \
	| tee _configure.out

#
gcc-pinfo-compile-install: gcc-pinfo-compile gcc-pinfo-install

gcc-pinfo-compile:
	cd $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION)-build; make | tee _compile.out

gcc-pinfo-compile-gcc:
	cd $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION)-build; make gcc | tee _compile.out


gcc-pinfo-install:
	cd $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION)-build; make install | tee _install.out

gcc-pinfo-install-gcc:
	cd $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION)-build; make install-gcc| tee _install.out

gcc-pinfo-diff:
	cd $(M_GCC_PINFO_TMPDIR); for f in `find gcc-$(GCC-PINFO-VERSION) -type f | grep '~$$'`; do if [ -f $$f ]; then echo remove $$f; rm $$f; fi; done
	-cd $(M_GCC_PINFO_TMPDIR); diff -Naurb --exclude=*.v87 --exclude=*.v93 gcc-$(GCC-PINFO-VERSION).ori/gcc gcc-$(GCC-PINFO-VERSION)/gcc >$(GCC_DIFF_NEXT)
	-cd $(M_GCC_PINFO_TMPDIR); diff -Naurb gcc-$(GCC-PINFO-VERSION).ori/libcpp gcc-$(GCC-PINFO-VERSION)/libcpp >$(LIBCPP_DIFF_NEXT);

gcc-pinfo-merge:
	cp $(GCC_DIFF_CUR) $(GCC_DIFF_CUR).latest
	rm $(filter-out %.new.diff,$(wildcard $(CURDIR)/$(HTMLTAGROOT)/gcc-$(GCC-PINFO-VERSION)*.diff))
	mv $(GCC_DIFF_CUR).latest $(CURDIR)/$(HTMLTAGROOT)/gcc-$(GCC-PINFO-VERSION).diff
	cp $(LIBCPP_DIFF_CUR) $(LIBCPP_DIFF_CUR).latest
	rm $(filter-out %.new.diff,$(wildcard $(CURDIR)/$(HTMLTAGROOT)/libcpp-$(GCC-PINFO-VERSION)*.diff))
	mv $(LIBCPP_DIFF_CUR).latest $(CURDIR)/$(HTMLTAGROOT)/libcpp-$(GCC-PINFO-VERSION).diff

# get ubuntu 4.4.7 sources and make tar from it
gcc-pinfo-preapre-ubuntu:
	sudo apt-get build-dep gcc-4.4
	sudo apt-get install devscripts
	rm -rf gcc-4.4-4.4.7
	apt-get source gcc-4.4
	cd gcc-4.4-4.4.7; debuild -i -us -uc -b 2>&1 | tee log.txt

gcc-pinfo-preapre-ubuntu-tar:
	rm -rf tmp_ext/gcc-g++-4.4.7-ubuntu.tar.bz2
	rm -rf tmp_ext/gcc-core-4.4.7-ubuntu.tar.bz2
	cd gcc-4.4-4.4.7; mv src gcc-4.4.7-ubuntu; \
		tar cvf ../tmp_ext/gcc-core-4.4.7-ubuntu.tar gcc-4.4.7-ubuntu
	bzip2 tmp_ext/gcc-core-4.4.7-ubuntu.tar
	mkdir -p tmp/gcc/gcc-4.4.7-ubuntu; cd tmp/gcc; \
		tar cvf ../../tmp_ext/gcc-g++-4.4.7-ubuntu.tar gcc-4.4.7-ubuntu
	bzip2 tmp_ext/gcc-g++-4.4.7-ubuntu.tar


gcc-pinfo-tags:
	-cd $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION); rm GPATH GRTAGS GTAGS
	cd $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION); find gcc include gcc libcpp  -type f | grep -e '.c$$\|.h$$' | gtags -i -f -

#4.4.7
#apt-get source gcc-4.4
#cd gcc-4.4-4.4.7/
#2059  sudo apt-get build-dep gcc-4.4
#2060  debuild -i -us -uc -b 2>&1 | tee log.txt
#2062  sudo apt-get install devscripts
#2063  debuild -i -us -uc -b 2>&1 | tee log.txt

# Configured with: -v
#          --with-pkgversion='Ubuntu/Linaro 4.4.7-8ubuntu1'
#          --with-bugurl='file:///usr/share/doc/gcc-4.4/README.Bugs'
#          --enable-languages=c,c++,fortran
#          --prefix=/usr
#          --program-suffix=-4.4
#          --enable-shared
#          --enable-linker-build-id
#          --with-system-zlib
#          --libexecdir=/usr/lib
#          --without-included-gettext
#          --enable-threads=posix
#          --with-gxx-include-dir=/usr/include/c++/4.4
#          --libdir=/usr/lib
#          --enable-nls
#          --with-sysroot=/
#          --enable-clocale=gnu
#          --enable-libstdcxx-debug
#          --disable-libmudflap
#          --disable-werror
#          --with-arch-32=i686
#          --with-tune=generic
#          --enable-checking=release
#          --build=x86_64-linux-gnu
#          --host=x86_64-linux-gnu
#          --target=x86_64-linux-gnu


##########################################################################
#

G-P-VERSION?=latest
G-P-SRC=$(CURDIR)/../gcc
# https://github.com/eiselekd/gcc.git

g:
	cd ..; git clone https://github.com/eiselekd/gcc.git

c_:
	-mkdir $(M_GCC_PINFO_TMPDIR)/gcc-$(G-P-VERSION)-build
	cd $(M_GCC_PINFO_TMPDIR)/gcc-$(G-P-VERSION)-build; $(G-P-SRC)/configure \
        --prefix=/opt/gcc-$(G-P-VERSION) --disable-nls --enable-languages=c \
	--target=x86_64-linux-gnu --host=x86_64-linux-gnu --build=x86_64-linux-gnu  \
	--disable-bootstrap --program-suffix=-pinfo --disable-multilib --enable-checking=release  \
        --disable-shared --disable-nls --disable-libstdcxx-pch \
	$(EXTRA_CONF_$(GCC-PINFO-VERSION)) \
	--with-sysroot=/ \
	| tee _configure.out

c:
	cd $(M_GCC_PINFO_TMPDIR)/gcc-$(G-P-VERSION)-build; make all-gcc | tee _compile.out

i:
	cd $(M_GCC_PINFO_TMPDIR)/gcc-$(G-P-VERSION)-build; make install-gcc| tee _install.out

a: c_ c i

ve:
	export FLYCHECK_GENERIC_SRC=$(shell readlink -f $(G-P-SRC)); \
	export FLYCHECK_GENERIC_BUILD=$(shell readlink -f $(M_GCC_PINFO_TMPDIR)/gcc-$(G-P-VERSION)-build); \
	export FLYCHECK_GENERIC_CMD=all-gcc; \
	emacs $(G-P-SRC) &

tags:
	-cd $(G-P-SRC); rm GPATH GRTAGS GTAGS
	cd $(G-P-SRC); find gcc include gcc libcpp  -type f | grep -e '.c$$\|.h$$' | gtags -i -f -

test_:
	/opt/gcc-$(G-P-VERSION)/bin/gcc-pinfo --verbose -c t/m.c  

test_2:
	/opt/gcc-$(G-P-VERSION)/bin/gcc-pinfo -c t/m0.c  

test:
	gdb --args /opt/gcc-$(G-P-VERSION)/libexec/gcc/x86_64-linux-gnu/7.0.1/cc1 -quiet -v -imultiarch x86_64-linux-gnu t/m.c -quiet -dumpbase m.c -mtune=generic -march=x86-64 -auxbase m -version -o /tmp/cctCZBFY.s
