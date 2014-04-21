htmltags
========

HTMLify C/C++ code

To get an impression on what htmltags does click here:
example Linux http://cfw.sourceforge.net/htmltag/init_32.c.pinfo.html
There is a little help text on the left pannel. The speed of the site is quite slow, be patient.

Compile yourself: 
$make gcc-pinfo
Note: --prefix is /opt, which has to be writable 
3. 
Goto /opt/gcc-4.2.1/libexec/gcc/i686-pc-linux-gnu/4.2.1: cc1 is a script that tests for the existence of htmltag.pl and starts it. Therefore add htmltag dir to PATH:
$export PATH=$PATH:`pwd`

The workflow to annotated c-source is as follows. Instead of gcc you start gcc-pinfo. This will output a file called [filename].pinfo. [filename].pinfo a c-frontend trace file. This file is then used by htmltag.pl to convert c-souce into a annotate dhtml site.

htmltag.pl is controlled by env-var CONFIG_HTMLTAG_STYLE. An example of CONFIG_HTMLTAG_STYLE is:
export CONFIG_HTMLTAG_STYLE='--style=ajax,multipage   --ajaxserver=localhost --ajaxdb=htmltag \
--ajaxdbprefix=htmltag --ajaxuser=root --outdir=/var/www/htdocs/htmltag --verbose \
--serverprefix=http://localhost/htmltag --serverroot=/var/www/htdocs/htmltag  --fidrand \
  --unifiedtemplatebase=/var/www/htdocs/htmltag/js  --ajaxfile    '
