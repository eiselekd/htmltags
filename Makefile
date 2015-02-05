M_GCC_PINFO_TMPDIR=tmp_gcc
M_EXTDIR=tmp_ext


#==================================
# Create patched gcc-pinfo compiler
#==================================
GCC-PINFO-VERSION?=4.2.1
DOWNLOAD_GCC-$(GCC-PINFO-VERSION)=gcc-core-$(GCC-PINFO-VERSION).tar.bz2
DOWNLOAD_G++-$(GCC-PINFO-VERSION)=gcc-g++-$(GCC-PINFO-VERSION).tar.bz2
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
	cd $(M_GCC_PINFO_TMPDIR); tar xvf $(CURDIR)/$(M_EXTDIR)/$(DOWNLOAD_GCC-$(GCC-PINFO-VERSION));  	tar xvf $(CURDIR)/$(M_EXTDIR)/$(DOWNLOAD_G++-$(GCC-PINFO-VERSION));  
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

gcc-pinfo-configure:
	-mkdir $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION)-build
	cd $(M_GCC_PINFO_TMPDIR)/gcc-$(GCC-PINFO-VERSION)-build; ../gcc-$(GCC-PINFO-VERSION)/configure \
        --prefix=/opt/gcc-$(GCC-PINFO-VERSION) --disable-nls --enable-languages=c,c++ \
	 --target=x86_64-linux-gnu --host=x86_64-linux-gnu --build=x86_64-linux-gnu  \
	--with-gnu-ld --disable-bootstrap --program-suffix=-pinfo --disable-multilib --enable-checking=release  \
        --disable-shared --disable-nls --disable-libstdcxx-pch \
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
