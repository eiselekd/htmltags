#!/usr/bin/perl
use File::Basename;
use File::Path;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Cwd;
use Cwd 'abs_path';

sub filename {
    my ($str) = @_;
    $str =~ s/([<>])/sprintf("_%02X_",ord($1))/eg;
    return $str;
}

sub readfile {
    my ($in) = @_;
    usage(\*STDOUT) if (length($in) == 0) ;
    open IN, "$in" or die "Reading \"$in\":".$!;
    local $/ = undef;
    $m = <IN>;
    close IN;
    return $m;
}

sub writefile {
    my ($out,$re,$temp) = @_;
    $out = filename($out);
    my $dir = dirname($out);
    if ($dir) {
        mkpath($dir);
    }
    open OUT, ">$out" or die ($out.$!);
    print OUT ($re);
    close OUT;
}

use Data::Dumper;
use Getopt::Long;

$cmdline = $0." ".join(" ",@ARGV);

sub usage { print("usage: $0 <infiles> [--dbgma=<id>] 

  --output=<file>  Output file (base for frame file) i.e.: test.html

mode 1: single html file
------------------------

mode 2: html file + xml file(s)
-------------------------------

  --style=xml      Activates xml output
  --xml=dir        Output xml files in directory. The directory name is derived from the output file name. 

  example:
 
  perl htmltag.pl test.c.pinfo --style=xml --xml=dir --output=test.html

mode 3: db (ajax)
-----------------

  --style=ajax     Activates database output
  --linkid=<nr>    link id

Common switches

  --norec         disable recursive linking inside macro expansion  
  --exportdb      specify the link database
  
debug switches:
  --dbgpa         output parsed macros (--dbgpan suppress link nodes)
  --dbgma=<n>     output parsed macro <n>       
  --dbgm          Dumper::Data of macro struct
  --dbgl          output 'lnk' assignments
  --dbgdecl       output 'decl' nodes (--dbgdef extra info for existing tokens)
  --dbgref        output 'ref' nodes (--dbgrefs output registered macro refs) 
  --dbgpaste      output '##' paste nodes
  --dbgfile       output file related 
  --dbgline       output file lines (used with --dbgpa)
  --dbglink       output 'link' nodes
  --dbgtoken      output tokenization
  --dbgprocess    output extra info on tokenization
  --dbgexport     output export information
  --dbgexpi       output extra export information
  --dbgtok=<f>    read file <f> and tokenize 
  --dbgdir        output macro define locations
  --dbgidreg      output token ids
  --dbgjs         insert javascript comments
  --dbgstruct     output 'strct' nodes
  --dbgmdom       output macro domains
  --dbgtool       set struct defs visible
  --dbgf          output file info
  --dbgfopen      output file opens
  --dbgaux        output auxinfo nodes 
  --dbgmid        output %mid token from macro registration  
  --dbgoutnomacro dont export macro definitions
  --dbglinktree=<f> write html linktree to <f>
  --dbgexid       show multiple token ids (when a replacement gets anchor)
  --dbgdep        output dependency parse
  --dbgnolnk      dont output lnk_jmp messages

\n"); exit(1); }
sub optio { print("$0 <infiles> \n"); exit(1); }

require "$Bin/tokenizer.pl";
require "$Bin/htmlentities.pl";

Getopt::Long::Configure(qw(bundling));
GetOptions(\%OPT,qw{
    quite|q+
    verbose|v+
    options
    outdir|d=s
    output|o=s
    template|t=s
    templatejs=s
    templatetop|t=s
    templateidx|t=s
    templatereload=s
    templatesajax=s
    unifiedtemplatebase=s
    dtreeimg=s
    serverprefix=s
    
    serverprefix_real=s
    
    serverroot=s
    style|s=s
    
    ajaxserver_real|s=s
    ajaxport_real|s=s
    ajaxuser_real|s=s
    ajaxpass_real|s=s
    ajaxdb_real|s=s
    ajaxdbprefix_real|s=s
    
    ajaxswitch_real
    
    ajaxserver|s=s
    ajaxport|s=s
    ajaxuser|s=s
    ajaxpass|s=s
    ajaxdb|s=s
    ajaxdbprefix|s=s
    xml|x=s
    unifyjs
    unifystructs
    linkid=s
    fid=s
    fidrand
    xmlfilesize|i=s
    pastecheck
    silent
    dbgpa dbgpan dbgexid
    dbgma=s
    idxcount=s
    dbgm dbgmid
    dbgls dbgl dbgdep
    dbgdef dbgref dbgrefs
    dbgpaste
    dbgfile dbgnolnk
    dbgline
    dbglink
    dbgexport
    dbgexpi
    dbglinktree=s
    dbgtok=s dbgmdep=s
    dbgtoken dbgdir dbgidreg norec
    dbgjs dbgstruct dbgmdom
    dbgprocess dbgdecl dbgtool
    dbgf dbgfopen dbgaux
    nocompress styles-from-export print-from-export
    mediawiki
    mediawiki-dbprefix=s
    mediawiki-dbserver=s
    mediawiki-dbuser=s
    mediawiki-dbpass=s
    mediawiki-db=s
    dbgoutnomacro
    ajaxfile
    ajaxfilecompress
},@g_more) or usage(\*STDERR);

	sub instring {
	    my ($str) = @_;
	    return "\"$str\"";
	}
	sub getBool {
	    my ($id) = @_;
	    return (exists($ENV{$id}) && ($ENV{$id} eq '1' || lc($ENV{$id}) eq 'true'));
	}
	sub getStringOption {
	    my ($opt,$id) = @_;
	    return "$opt".instring($ENV{$id})." " if (exists($ENV{$id}) && length($ENV{$id}));
	    return "";
	}

if (exists($OPT{'styles-from-export'})) {
    my $r = "";
    if (exists($ENV{'CONFIG_HTMLTAG_TYPE'})) {

	
	if ($ENV{'CONFIG_HTMLTAG_TYPE'} =~ m/HTMLTAG_SIMPLE/) {
	    $r .= " --style=simple";
	    $r .= ",multipage " if (exists($ENV{'CONFIG_HTMLTAG_MULTIPAGE'}) && ($ENV{'CONFIG_HTMLTAG_MULTIPAGE'} eq 'true' || $ENV{'CONFIG_HTMLTAG_MULTIPAGE'} == 1) );
	    $r .= " ";
	} elsif ($ENV{'CONFIG_HTMLTAG_TYPE'} =~ m/HTMLTAG_AJAX/) {
	    $r .= " --style=ajax";
	    $r .= ",multipage " if (exists($ENV{'CONFIG_HTMLTAG_MULTIPAGE'}) && ($ENV{'CONFIG_HTMLTAG_MULTIPAGE'} eq 'true' || $ENV{'CONFIG_HTMLTAG_MULTIPAGE'} == 1) );
	    $r .= " ";
	    $r .= " --ajaxserver=".instring($ENV{'CONFIG_HTMLTAG_AJAX_DBSERVER'}) if (exists($ENV{'CONFIG_HTMLTAG_AJAX_DBSERVER'}) && length($ENV{'CONFIG_HTMLTAG_AJAX_DBSERVER'}));
	    $r .= " --ajaxport=".instring($ENV{'CONFIG_HTMLTAG_AJAX_PORT'}) if (exists($ENV{'CONFIG_HTMLTAG_AJAX_PORT'}) && length($ENV{'CONFIG_HTMLTAG_AJAX_PORT'}));
	    $r .= " --ajaxdb=".instring($ENV{'CONFIG_HTMLTAG_AJAX_DB'}) if (exists($ENV{'CONFIG_HTMLTAG_AJAX_DB'}) && length($ENV{'CONFIG_HTMLTAG_AJAX_DB'}) );
	    $r .= " --ajaxdbprefix=".instring($ENV{'CONFIG_HTMLTAG_AJAX_DBPREFIX'}) if (exists($ENV{'CONFIG_HTMLTAG_AJAX_DBPREFIX'}) && length($ENV{'CONFIG_HTMLTAG_AJAX_DBPREFIX'}) );
	    $r .= " --ajaxuser=".instring($ENV{'CONFIG_HTMLTAG_AJAX_DBUSER'}) if (exists($ENV{'CONFIG_HTMLTAG_AJAX_DBUSER'}) && length($ENV{'CONFIG_HTMLTAG_AJAX_DBUSER'}) );
	    $r .= " --ajaxpass=".instring($ENV{'CONFIG_HTMLTAG_AJAX_DBPASS'}) if (exists($ENV{'CONFIG_HTMLTAG_AJAX_DBPASS'}) && length($ENV{'CONFIG_HTMLTAG_AJAX_DBPASS'}) );
	} elsif ($ENV{'CONFIG_HTMLTAG_TYPE'} =~ m/HTMLTAG_XML/) {
	    $r .= " --style=xml";
	    $r .= ",multipage " if (exists($ENV{'CONFIG_HTMLTAG_MULTIPAGE'}) && ($ENV{'CONFIG_HTMLTAG_MULTIPAGE'} eq 'true' || $ENV{'CONFIG_HTMLTAG_MULTIPAGE'} == 1) );
	    $r .= " ";
	}
	$r .= " --outdir=".instring($ENV{'CONFIG_HTMLTAG_OUTPUTDIR'}) if (exists($ENV{'CONFIG_HTMLTAG_OUTPUTDIR'}) && length($ENV{'CONFIG_HTMLTAG_OUTPUTDIR'}));
	if (exists($ENV{'CONFIG_HTMLTAG_OPTIONS'}) && length($ENV{'CONFIG_HTMLTAG_OPTIONS'})) {
	    $r .= " --verbose" if ($ENV{'CONFIG_HTMLTAG_OPTIONS'} =~ m/--verbose/);
	    $r .= " --dbgoutnomacro" if ($ENV{'CONFIG_HTMLTAG_OPTIONS'} =~ m/--dbgoutnomacro/);
	}
	$r .= " --serverprefix=".instring($ENV{'CONFIG_HTMLTAG_SERVER_PREFIX'}) if (exists($ENV{'CONFIG_HTMLTAG_SERVER_PREFIX'}) && length($ENV{'CONFIG_HTMLTAG_SERVER_PREFIX'}));
	$r .= " --serverroot=".instring($ENV{'CONFIG_HTMLTAG_SERVER_ROOT'}) if (exists($ENV{'CONFIG_HTMLTAG_SERVER_ROOT'}) && length($ENV{'CONFIG_HTMLTAG_SERVER_ROOT'}));
	$r .= " --unifiedtemplatebase=".instring($ENV{'CONFIG_HTMLTAG_UNIFIEDTEMPLATEBASE'}) if (exists($ENV{'CONFIG_HTMLTAG_SERVER_ROOT'}) && length($ENV{'CONFIG_HTMLTAG_UNIFIEDTEMPLATEBASE'}));
	
	if (getBool('CONFIG_HTMLTAG_MEDIAWIKI')) {
	    $r .= " --mediawiki ";
	    $r .= getStringOption(" --mediawiki-dbprefix=",'CONFIG_HTMLTAG_MEDIAWIKI_DBPREFIX');
	    $r .= getStringOption(" --mediawiki-dbserver=",'CONFIG_HTMLTAG_MEDIAWIKI_DBSERVER');
	    $r .= getStringOption(" --mediawiki-dbuser=",'CONFIG_HTMLTAG_MEDIAWIKI_DBUSER');
	    $r .= getStringOption(" --mediawiki-dbpass=",'CONFIG_HTMLTAG_MEDIAWIKI_DBPASS');
	    $r .= getStringOption(" --mediawiki-db=",'CONFIG_HTMLTAG_MEDIAWIKI_DB');
	}
	
    }
    print("\n########################\n# options for $Bin/".basename($0)." (called from gcc)\n");
    print(_alignarray([map { ["#",$_.":",$ENV{$_}] } sort grep { exists($ENV{$_}) } grep { $_ =~ m/HTMLTAG/ } keys %ENV]));
    print("export CONFIG_HTMLTAG_STYLE=`echo -n $r`\n");
    #print Dumper(\%ENV);
    exit(0);
}


$opt_idxcount = $OPT{'idxcount'} || 100;
$nocompress  = $OPT{'nocompress'} || 0;
$norec       = $OPT{'norec'} || 0;

$exportdb      = $OPT{'exportdb'} || "exportdb.xml";
$exportdb_content = "";
$style_multi   = 0;
$style_repspan = 1;
$style_recspan = 0;
$style_ajax    = 0;
$style_xml     = 0;
$style_simple  = 1;
$style_frames  = 1;
$style_xmlmultifile  = 0;
if ($OPT{style}) {
    my $style = $OPT{style};
    $style_multi   = 1                       if ($style =~ s/multipage//g);
    $style_frames  = 0                       if ($style =~ s/noframes//g);
    ($style_ajax = 1, $style_xml = 0)        if ($style =~ s/ajax//g);
    ($style_repspan = 1, $style_recspan = 0, $style_ajax = 0, $style_xml = 1, $style_simple = 0, $style_xmlmultifile = 1) if ($style =~ s/xmlmultifile//g);
    ($style_repspan = 1, $style_recspan = 0, $style_ajax = 0, $style_xml = 1, $style_simple = 0)                          if ($style =~ s/xml//g);
    ($style_ajax = 0, $style_xml = 0, $style_simple = 1)                          if ($style =~ s/simple//g);
    ($style_repspan = 0, $style_recspan = 1) if ($style =~ s/recspan//g);
    ($style_repspan = 1, $style_recspan = 0) if ($style =~ s/repspan//g);
    $style =~ s/,//g;
    die("Unknown style option ".$OPT{'style'}) if (length($style) != 0);
}
$style_xmldir    = 0;
$style_xmlfilesize   = 4000;
$style_xmldirsize   = 4000;
$style_xmlmultifile  = 1;
if ($OPT{xml}) {
    my $stylexml = $OPT{xml};
    $style_xmldir     = 1 if ($stylexml =~ s/dir//g);
    
}
$cfw_file = "$Bin/template/cfw";
$sajax_file = "$Bin/template/cfwSajax";

$mediawiki = 0;
if ($OPT{'mediawiki'}) {
    $mediawiki = 1;
    $re_mediawiki_server = $OPT{'mediawiki-dbserver'} || "localhost";
    $re_mediawiki_user = $ajaxuser = $OPT{'mediawiki-dbuser'} || "root";
    $re_mediawiki_pass = $ajaxpass = $OPT{'mediawiki-dbpass'} || "";
    $re_mediawiki_db = $ajaxdb = $OPT{'mediawiki-db'} || "wikidb";
    $re_mediawiki_prefix = $OPT{'mediawiki-dbprefix'} || "mediawiki";

require "$Bin/wikidb.inc.pl";
    
}

$re_sajax_port = $ajaxport = ($OPT{'ajaxport'} ? ":".$OPT{'ajaxport'} : "");
$re_sajax_server_real = $re_sajax_server = $ajaxserver = $OPT{'ajaxserver'} || "localhost";
$re_sajax_user_real = $re_sajax_user = $ajaxuser = $OPT{'ajaxuser'} || "root";
$re_sajax_pass_real = $re_sajax_pass = $ajaxpass = $OPT{'ajaxpass'} || "";
$re_sajax_db_real = $re_sajax_db = $ajaxdb = $OPT{'ajaxdb'} || "htmltag";
$re_sajax_prefix_real = $re_sajax_prefix = $OPT{'ajaxdbprefix'} || "htmltag";

$re_sajax_server_real = $OPT{'ajaxserver_real'} if (defined($OPT{'ajaxserver_real'}));
$re_sajax_user_real = $OPT{'ajaxuser_real'} if (defined($OPT{'ajaxuser_real'}));
$re_sajax_pass_real = $OPT{'ajaxpass_real'} if (defined($OPT{'ajaxpass_real'}));
$re_sajax_db_real = $OPT{'ajaxdb_real'} if (defined($OPT{'ajaxdb_real'}));
$re_sajax_prefix_real = $OPT{'ajaxdbprefix_real'} if (defined($OPT{'ajaxdbprefix_real'}));

#print $re_sajax_prefix;
#exit;

if (exists($OPT{'print-from-export'})) {
    my $env = getStringOption('','CONFIG_HTMLTAG_STYLE');
    print("### htmltag.pl options ###\n");
    if ($style_ajax) {
        print (" Style     : AJAX with [[$re_sajax_user:$re_sajax_pass]\@$re_sajax_server:$re_sajax_db]:${re_sajax_prefix}\n");
    } elsif ($style_xml) {
        print (" Style     : XML\n");
    } else {
        print (" Style     : SIMPLE\n");
    }
    if ($mediawiki) {
        print (" Mediawiki : Pageinject with [[$re_mediawiki_user:$re_mediawiki_pass]\@$re_mediawiki_server:$re_mediawiki_db]:${re_mediawiki_prefix}\n");
    }
    exit(0);
} 

$re_cfw_server_real = $re_cfw_server = $serverprefix = $OPT{'serverprefix'};
if (defined($OPT{'serverprefix_real'})) {
    $re_cfw_server = $serverprefix = $OPT{'serverprefix_real'};
}

$re_cfw_root = $OPT{'serverroot'};
$re_cfw_root .= "/" if(!($re_cfw_root =~ m/\/$/)); 	
#$re_cfw_root .= $outdir;
#$re_cfw_root .= "/" if(!($re_cfw_root =~ m/\/$/));
$re_cfw_root .= "_db";
$re_from_db_real = $re_from_db = $OPT{'ajaxfile'} ? ($OPT{'ajaxfilecompress'} ? 2 : 1) : 0;	

$outdir = $OPT{'outdir'} || "";
$outdir .= "/" if (length($outdir) && !($outdir =~ /\/\s*$/));
$outputdb = $outdir."/_db";
$re_cfw_root_real = $outputdb;

if ($style_ajax) {
    $re_sajax = readfile($sajax_file.".php");
    $re_cfw_config = readfile($cfw_file."Config.php.templ");
    $re_sajax_config = readfile($sajax_file."Config.php.templ");
    $re_sajax_php = readfile("$Bin/template/ajax.php");
    $re_sajax_show = "<?php cfwsajax_show_javascript();?>";
    
    $re_sajax_port = $ajaxport = ($OPT{'ajaxport'} ? ":".$OPT{'ajaxport'} : "");
    $re_sajax_server = $ajaxserver = $OPT{'ajaxserver'} || "localhost";
    $re_sajax_user = $ajaxuser = $OPT{'ajaxuser'} || "root";
    $re_sajax_pass = $ajaxpass = $OPT{'ajaxpass'} || "";
    $re_sajax_db = $ajaxdb = $OPT{'ajaxdb'} || "htmltag";
    $re_sajax_prefix = $OPT{'ajaxdbprefix'} || "htmltag";
    
    $re_sajax_php =~ s/¶([^¶]+)¶/$$1/eg;
    $re_sajax_config =~ s/¶([^¶]+)¶/$$1/eg;
    $re_cfw_config =~ s/¶([^¶]+)¶/$$1/eg;
    
    if (!($OPT{'ajaxfile'})) {
    use DBI; 
    $dbh = DBI->connect("DBI:mysql:$ajaxdb:$ajaxserver$ajaxport",$ajaxuser,$ajaxpass) if !($OPT{'ajaxfile'}); 
    
    my %tables = ();
    map { 
	$tables{$_} = 1;
	if ($_ =~ /`([a-zA-Z0_9_]+)`.`([a-zA-Z0_9_]+)`/) {
	    $tables{$_} = $2;
	}
    } $dbh->tables() ;
    
    if (!scalar(grep { $_ =~ /`${re_sajax_prefix}_html`/ } $dbh->tables())) {
	print("Create table ${re_sajax_prefix}_html\n");
	$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_html` (
                              `htmltag_html_name` varchar(255) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_html_text` MEDIUMTEXT NOT NULL,
                              `htmltag_html_fid` int(11) NOT NULL default '0',
                              `htmltag_html_linkid` int(11) NOT NULL default '0',
                              KEY `htmltag_html_name` (`htmltag_html_name`));");
	$ctbl->execute();
    }
    if (!scalar(grep { $_ =~ /`${re_sajax_prefix}_file`/ } $dbh->tables())) {
	print("Create table ${re_sajax_prefix}_file\n");
	$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_file` (
                              `htmltag_file_fid` int(11) NOT NULL auto_increment,
                              `htmltag_file_linkid` int(11) NOT NULL default '0',
                              `htmltag_file_path` MEDIUMTEXT NOT NULL,
                              `htmltag_file_fn` varchar(512) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_file_cfgid` int(11) NOT NULL default '0',
                               PRIMARY KEY  (`htmltag_file_fid`));");
	$ctbl->execute();
    }
    if (!scalar(grep { $_ =~ /`${re_sajax_prefix}_link`/ } $dbh->tables())) {
	print("Create table ${re_sajax_prefix}_link\n");
	$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_link` (
                              `htmltag_link_linkid` int(11) NOT NULL,
                              `htmltag_link_tree` MEDIUMTEXT NOT NULL,
                              `htmltag_link_fn` varchar(512) character set latin1 collate latin1_bin NOT NULL default '',
                               PRIMARY KEY  (`htmltag_link_linkid`));");
	$ctbl->execute();
    }
    # if (!scalar(grep { $_ eq "`${re_sajax_prefix}_filetree`" } $dbh->tables())) {
# 	print("Create table ${re_sajax_prefix}_filetree\n");
# 	$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_filetree` (
#                               `htmltag_filetree_id` int(11) NOT NULL auto_increment,
#                               `htmltag_filetree_pid` int(11) NOT NULL default '0',
#                               `htmltag_filetree_fid` int(11) NOT NULL default '0',
#                               `htmltag_filetree_linkid` int(11) NOT NULL default '0',
#                               `htmltag_filetree_fn` varchar(512) character set latin1 collate latin1_bin NOT NULL default '',
#                               `htmltag_filetree_cfgid` int(11) NOT NULL default '0',
#                                PRIMARY KEY  (`htmltag_filetree_id`));");
# 	$ctbl->execute();
#     }
    if (!scalar(grep { $_ =~ /`${re_sajax_prefix}_cfg`/ } $dbh->tables())) {
	print("Create table ${re_sajax_prefix}_cfg\n");
	$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_cfg` (
                              `htmltag_cfg_cfgid` int(11) NOT NULL auto_increment,
                              `htmltag_cfg_desc` varchar(512) character set latin1 collate latin1_bin NOT NULL default '',
                               PRIMARY KEY  (`htmltag_cfg_cfgid`));");
	$ctbl->execute();
    }
    if (!scalar(grep { $_ =~ /`${re_sajax_prefix}_macro`/ } $dbh->tables())) {
	print("Create table ${re_sajax_prefix}_macro\n");
	$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_macro` (
                              `htmltag_macro_name` varchar(255) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_macro_mid`  varchar(255) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_macro_fid`  int(11) NOT NULL default '0',
                              `htmltag_macro_desc` MEDIUMTEXT NOT NULL,
                               KEY `htmltag_macro_name` (`htmltag_macro_name`));");
	$ctbl->execute();
    }
    if (!scalar(grep { $_ =~ /`${re_sajax_prefix}_export`/ } $dbh->tables())) {
	print("Create table ${re_sajax_prefix}_export\n");
	$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_export` (
                              `htmltag_export_name` varchar(255) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_export_eid`  int(11) NOT NULL  ,
                              `htmltag_export_url`  varchar(512) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_export_fid` int(11) NOT NULL default '0',
                              `htmltag_export_linkid` int(11) NOT NULL default '0',
                              `htmltag_export_desc` MEDIUMTEXT NOT NULL,
                               KEY `htmltag_export_name` (`htmltag_export_name`));");
	$ctbl->execute();
    }
    if (!scalar(grep { $_ =~ /`${re_sajax_prefix}_call`/ } $dbh->tables())) {
	print("Create table ${re_sajax_prefix}_call\n");
	$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_call` (
                              `htmltag_call_id` int(11) NOT NULL auto_increment,
                              `htmltag_call_from` varchar(255) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_call_to`   varchar(255) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_call_to_name`  varchar(255) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_call_url`  varchar(512) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_call_linkid` int(11) NOT NULL default '0',
                              `htmltag_call_desc` MEDIUMTEXT NOT NULL,
                               PRIMARY KEY  (`htmltag_call_id`));");
	$ctbl->execute();
    }
    if (!scalar(grep { $_ =~ /`${re_sajax_prefix}_func`/ } $dbh->tables())) {
	print("Create table ${re_sajax_prefix}_func\n");
	$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_func` (
                              `htmltag_func_id` int(11) NOT NULL auto_increment,
                              `htmltag_func_name`  varchar(255) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_func_fid`  int(11) NOT NULL default '0',
                              `htmltag_func_linkid` int(11) NOT NULL default '0',
                              `htmltag_func_desc` MEDIUMTEXT NOT NULL,
                               PRIMARY KEY  (`htmltag_func_id`));");
	$ctbl->execute();
    }
    if (!scalar(grep { $_ =~ /`${re_sajax_prefix}_struct`/ } $dbh->tables())) {
	print("Create table ${re_sajax_prefix}_struct\n");
	$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_struct` (
                              `htmltag_struct_id` int(11) NOT NULL auto_increment,
                              `htmltag_struct_name` varchar(255) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_struct_sid`  varchar(255) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_struct_fid`  int(11) NOT NULL default '0',
                              `htmltag_struct_linkid`  int(11) NOT NULL default '0',
                              `htmltag_struct_desc` MEDIUMTEXT NOT NULL,
                               PRIMARY KEY  (`htmltag_struct_id`),
                               KEY `htmltag_struct_name` (`htmltag_struct_name`));");
	$ctbl->execute();
    }
    if (!scalar(grep { $_ =~ /`${re_sajax_prefix}_structelem`/ } $dbh->tables())) {
	print("Create table ${re_sajax_prefix}_structelem\n");
	$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_structelem` (
                              `htmltag_structelem_id` int(11) NOT NULL auto_increment,
                              `htmltag_structelem_sid` int(11) NOT NULL default '0',
                              `htmltag_structelem_idx` int(11) NOT NULL default '0',
                              `htmltag_structelem_name` varchar(255) character set latin1 collate latin1_bin NOT NULL default '',
                              `htmltag_structelem_desc` MEDIUMTEXT NOT NULL,
                              `htmltag_structelem_typ` MEDIUMTEXT NOT NULL,
                               PRIMARY KEY  (`htmltag_structelem_id`),
                               KEY `htmltag_structelem_name` (`htmltag_structelem_name`));");
	$ctbl->execute();
    }
    if (!scalar(grep { $_ =~ /`${re_sajax_prefix}_log`/ } $dbh->tables())) {
	#print("Create table ${re_sajax_prefix}_log\n");
	#$ctbl = $dbh->prepare("CREATE TABLE `${re_sajax_prefix}_log` (
        #                      `htmltag_log_id` int(11) NOT NULL auto_increment,
        #                      `htmltag_log_name` MEDIUMTEXT NOT NULL,
        #                       PRIMARY KEY  (`htmltag_log_id`),
        #                      KEY `htmltag_log_name` (`htmltag_log_name`));");
	#$ctbl->execute();
    }
    }
}

if ($style_xml) {
    read_exportdb();
}
@do_export = ();
%do_export_public = ();
%do_export_public_id = ();
%do_export_declid = ();
%do_export_rec = ();

if ($OPT{options}) {
    my $p = $0;
    optio();
}

sub equalleangth {
    my (@a) = @_;
    my $m = 0;
    map {
        my $l = length($_);
        $m = $l if ($l > $m);
    } @a;
    return map { _setlength($_,$m) } @a; 
}

sub _setlength {
    my ($e,$l) = @_;
    my $len = length(_unbold($e));
    if ($len < $l) {
	my $i = $l-$len;
	$e .= join('',' ' x $i);
    }
    return $e;
}

sub _bold {
    my ($s) = @_;
    return "\033[4m\033[1m$s\033[0m";
}

sub _unbold {
    my ($s) = @_;
    $s =~ s/\033\[[0-9]m//g;
    return $s;
}

sub _alignarray {
    my ($c) = @_;
    my @max = ();
    my @cc = ();
    for(my $j = 0; $j < scalar(@{$c}); $j++) {
        if (ref($c->[$j]) ne 'UNALIGNED') {
            for(my $i = 0; $i < scalar(@{$c->[$j]}); $i++) {
                if ("".$c->[$j][$i] ne "") {
                    my $l = length(_unbold($c->[$j][$i]));
                    $max[$i] = $l > $max[$i] ? $l : $max[$i];
                }
            } 
            push(@cc,      [@{$c->[$j]}]);
        }  else {
            push(@cc,bless [@{$c->[$j]}], 'UNALIGNED');
        }
    }
    for(my $i = 0; $i < scalar(@cc); $i++) {
        if (ref($cc[$i]) ne 'UNALIGNED') {
            for(my $j = 0; $j < scalar(@{$cc[$i]}); $j++) {
                $cc[$i][$j] = _setlength($cc[$i][$j],$max[$j]+2)
            }
        }
    }
    my $d = "";
    for(my $i = 0; $i < scalar(@cc); $i++) {
        my $l = join("",@{$cc[$i]});
        $l =~ s/\s*$//g;
	$d .= $l."\n";
    }
    return $d;
};

$templatesajax  = "$Bin/template/body.sajax" || $OPT{templatesajax};
$reloadtemplate = "$Bin/template/reload.html" || $OPT{templatereload};
$dtreeimages = "$Bin/template/img" || $OPT{dtreeimg};
$reloadtemplate_body = readfile($reloadtemplate);
$template = "$Bin/template/body.html" || $OPT{template};
if ($style_ajax && $templatesajax) {
    $template = $templatesajax;
    $templatesajax = $templatesajax.".rep";
}

$templatejs = "$Bin/template/body" || $OPT{templatejs};
$outputpost = ".html";


$output   = $OPT{output} || "a.html" ;
$outputdir = dirname($output);
$outputpost = $1 if ($output =~ /(\.[^\.]+$)/);
$output   =~ s/\.[^\.]+$//;
$outputtop = $outputxml = $output;
$templatetop = "$Bin/template/top.html" || $OPT{templatetop};
$templateidx = "$Bin/template/idx.html" || $OPT{templateidx};

if ($style_frames) {
    $outputidx = $output.".idx";
    $output    .= ".main";
}
#$serverprefix = $OPT{'serverprefix'};
$serverroot = $OPT{'serverroot'};
$onserver = 0;
if ($OPT{'serverprefix'} && $OPT{'serverroot'}) {
    die ("--outdir ($outdir) must be in path of --serverroot ($serverroot)") if (substr($outdir,0,length($serverroot)) ne $serverroot);
    #$serverprefix .= substr($outdir,length($serverroot));
    $onserver = 1;
}

sub insertpost {
    my ($f,$p) = @_;
    ($f =~ /^(.*)(\.[^\.]+$)/) or die("Cannot split filename $f\n");
    my ($pre,$post) = @_;
    return $pre.$p,$post;
}


sub linenr { my ($p) = @_; my $c = 0; if($p =~ /\n([^\n]*)$/) { $c = length($1) }; my $r = ($p =~ s/\n//g) + 1; return sprintf("%5d:%4d",$r,$c);  }

$RE_balanced_squarebrackets =    qr'(?:[\[]((?:(?>[^\[\]]+)|(??{$RE_balanced_squarebrackets}))*)[\]])';
$RE_balanced_smothbrackets =     qr'(?:[\(]((?:(?>[^\(\)]+)|(??{$RE_balanced_smothbrackets}))*)[\)])';

@INCSTACK = (@ARGV[0]);
@idx = ();
my $i = shift(@INCSTACK);
$b = readfile($i);
%d_dep =  ();
%m_dep =  ();
%m_dep_n =  ();
@m_def_ref = ();
if ($b =~ m/<dep-info:(.*)dep-info>/ms) {
    sub scan_macro_list {
	my ($l) = @_; my @m = (); my %m = ();
	my @l = grep { length($_) } split('[ ]+',$l);
	map { 
	    die("Misformed macro list \"$_\"\n") if (!($_ =~ /\s*([0-9]+)$RE_balanced_smothbrackets/s) );
	    $m{$1} = $2;
	} @l;
	return map { [$_,$m{$_}] } keys %m;
    }
    sub scan_decl_list {
	my ($l) = @_; my @d = (); my %d = ();
	my @l = grep { length($_) } split('[ ]+',$l);
	map { 
	    die("Misformed decl list '$l'\n") if (!($_ =~ /\s*([0-9]+)/s) );
	    $d{$1} = 1;
	} @l;
	return keys %d;
    }
    
    $dep = $1;
    my ($pre,$c) = ($`,$&);
    $b = substr($b,0,length($pre)).substr($b,length($pre.$c));
    $RE_dep = qr"(?:dep\s+([0-9]+):\s+$RE_balanced_squarebrackets\s*\n\s*m:$RE_balanced_squarebrackets\s*\n\s*d:$RE_balanced_squarebrackets)";
    $RE_mac = qr"(?:mac\s+([0-9]+)\s*$RE_balanced_smothbrackets:\s+$RE_balanced_squarebrackets\s*\n\s*$RE_balanced_squarebrackets)";
    while($c =~ /$RE_dep/gms) {
	my ($did,$pos,$m,$d) = ($1,$2,$3,$4);
	print ("Found decl dependency $did: at $pos\n m: [$m]\n d: [$d]\n") if ($OPT{'dbgdep'});
	map { 
	    $d_dep{$did}{'mdep'}{$$_[0]} = 1;
	} scan_macro_list($m);
	map { 
	    $d_dep{$did}{'ddep'}{$_} = 1;
	} scan_decl_list($d);
	
    }
    while($c =~ /$RE_mac/gms) {
	my ($mid,$n,$pos,$m) = ($1,$2,$3,$4);
	$m_dep{$mid}{'n'} = $n;
	$m_dep_n{$n} = $mid;
	if ($pos =~ /^([^:]+):([0-9]+)$/) {
	    my $ref = { 'refdfile' => $1, 'refdline' => $2, 'n' => $n,'typ' => 'macro'};
 	    $m_dep{$mid}{'pos'} = [$1,$2,$ref];
	    push(@m_def_ref,$ref);
	}
	
	print ("Found macr $n dependency $mid: at $pos\n m: [$m]\n") if ($OPT{'dbgdep'});
	map { 
	    $m_dep{$mid}{'mdep'}{$$_[0]} = 1;
	} scan_macro_list($m);
    }
}

sub get_mdep_source {
    my ($dbgmdep) = @_;
    if (defined($m_dep_n{$dbgmdep})) {
	my @d = get_all_mdep($m_dep_n{$dbgmdep});
    } 
} 

sub get_all_mdep {
    my ($mid) = @_;
    my %id = ($mid=>1);
    sub get_all_mdep_r {
	my ($id,$mid) = @_;
	my @m = grep { !defined($$id{$_}) } keys (%{$m_dep{$mid}{'mdep'}});
	map { $$id{$_} = 1 } @m;
	map { get_all_mdep_r($id,$_) } @m;
    }
    get_all_mdep_r(\%id, $mid);
    return map { $m_dep{$_} } sort { $a <=> $b } keys %id;
}

my @b = split("\n",$b);
my @l = ();
my %id = ();
my %idm = (); # extension to %id if tokens with same tokid appear. Tis is the case in the followinf example:
	    ##define a c
            ##define c(v1) d(v1)
            ##define d(v) int v 

my %mid = ();

my %mmid = (); #for a token lookup last macro path assigned
my $mmdomid = 1; #next domain id
my %mmdom = (); #lookup domain for a path
my %mdom = (); 
my %tok2mid = ();

my %pid = ();
my @pp = ();
my %ppid = ();
my %line = ();
my $cfile = "<unknown>";
my $cline = 0;
my %ml = (); my @ml = (); my %m = ();
my $o = "";

if ($OPT{dbgtok}) {
    my $tok = readfile($OPT{dbgtok});
    $OPT{dbgtoken} = 1;
    tokenize($tok);
    exit(0);
}

$dirid = 1;
%dirs = ();

$RE_comment_Cpp =                q{(?:\/\*(?:(?!\*\/)[\s\S])*\*\/|\/\/[^\n]*\n)};

$RE_lmark_line       = qr'(?:^# ([0-9]+) (.*)$)';

$RE_imark_line       = qr'(?:(?:([0-9]+)@)?# include ([\+\-]{1,2}) (.*)$)';
$RE_direcinc_line    = qr'(?:(#\s*include\s*)((?:<[^>]+>|"[^"]+"))(?:[0-9\s]+)?$)';

# rename %s
$RE_rename_line      = qr'(?:# rename (.*)$)';

$RE_token_line       = qr'(?:^([0-9]+)@([0-9]+):([^:]*):([A-Z]+)\t\[[ ]?(.*)$)';
$RE_paste_line       = qr'(?:^([0-9]+)@([0-9]+):(\[[^\]]*\])\(([0-9]+)##([0-9]+)\s*=>\s*([0-9]+)\)$)'; #12@181197:[2310.2315.2339](181197##190681 => 190687)
$RE_macro_line       = qr'(?:^\t((?:<=)?[0-9]+)\t([\(\[][0-9\.]+[\)\]])\t{1,2}([^\t]+)\t([^\t]+)\t\[[ ]?(.*)$)';


# ##/* /usr/include/stdlib.h:474:NC */ extern int random_r (struct random_data *, int32_t *);
$RE_auxinfo_line = qr'(?:^##/\* ([^:]*):([0-9]+):([A-Z])([A-Z]) \*/ (.*)$)';

#6->7	#:0->1
$RE_dstate_line       = qr'(?:^([0-9]+)->([0-9]+)\t#:([0-9]+)->([0-9]+)$)';

##define 	__GNUC__:[<built-in>:0]-[<built-in>:0]
$RE_define_line       = qr"(?:^\#define\(\@([0-9]+)\)\s+([a-zA-Z0-9_]+):$RE_balanced_squarebrackets-$RE_balanced_squarebrackets:(.*)$)";

#18@421: b:      TOK     [b
$RE_mcall_line       = qr'(?:^([0-9]+)@([0-9]+:#?)\t([a-zA-Z_0-9]+:)\t([^\t]+)\t\[[ ]?(.*)$)';

$RE_cdecl_line       = qr'(?:^([0-9]+)\s*<=\[(.*)$)';
$RE_direc_line       = qr'(?:^#(.*)$)';

$RE_link_line        = qr'(?:^link:decl:([a-zA-Z_0-9]+)\s*((?:e)?)$)';


#403(@8) == func^ [func2]
$RE_func_decl        = qr"(?:([0-9]+)\(\@([0-9]+)\)\s*== func([ \^])\s*$RE_balanced_squarebrackets\s*$)";
#{{+:func1
$RE_funcbody_start     = qr'(?:^\{\{\+:([<>a-zA-Z_0-9]+):\[)';
#}}-:func1
$RE_funcbody_end       = qr'(?:^\}\}\-:([<>a-zA-Z_0-9]+):\[)';


#397(@4) <=[  ref  (a)  decl at test1.c:15  type [atyp *] typdecl at: test1.c:15 
$RE_ref_line         = qr"(?:([0-9]+)\(\@([0-9]+)\)\s*<=\[\s*([ \(]ref[ \)])([ \^])\s*\(([a-zA-Z_0-9]+)\)\s+decl at ([^:]*):([0-9]+)\s+type $RE_balanced_squarebrackets typdecl at: ([^:]*):([0-9]+)\s*$)";

#19343(@0) <=[ (ref)^ (l8ld_readline)  type <unknown> 
$RE_ref_short_line         = qr"(?:([0-9]+)\(\@([0-9]+)\)\s*<=\[\s*([ \(]ref[ \)])([ \^])\s*\(([a-zA-Z_0-9]+)\)\s+)";

#379 <=[ tdef (@1->d@3) [@(2)->@(1)_a :_b] decl [test.c:1]-[test.c:7]
$RE_tdef_line    = qr"(?:([0-9]+)\s*<=\[ ((?:tdef)) \(\@([0-9]+)\->d\@([0-9]+)\) $RE_balanced_squarebrackets decl $RE_balanced_squarebrackets\-$RE_balanced_squarebrackets)";


#20077 <=[ strct 4 [@(4)struct { __mbstate_t__mbstate_t __state; } ] decl started at: ]/usr/include/_G_config.h:27]-[/usr/include/_G_config.h:30]
#20079(@4) <=[{decl} [__pos] type [__off_t ] decl at: <built-in>:0
#20082(@4) <=[{decl} [__state] type [__mbstate_t ] decl at: /usr/include/wchar.h:77
$RE_struct_line    = qr"(?:([0-9]+)\s*<=\[([0-9]+) ((?:struct|union|enum)) ([^\s]+) $RE_balanced_squarebrackets decl started at: $RE_balanced_squarebrackets-$RE_balanced_squarebrackets$)";
$RE_structdec_line = qr"(?:([0-9]+)\(\@([0-9]+)\)\s*<=\[\{decl\}\s+$RE_balanced_squarebrackets start $RE_balanced_squarebrackets type $RE_balanced_squarebrackets decl at: ([^:]*):([0-9]+)\s*$)";
$RE_enumdec_line = qr"(?:([0-9]+)\(\@([0-9]+)\)\s*<=\[\{enum\}\s+$RE_balanced_squarebrackets value $RE_balanced_squarebrackets\s*$)";

#401 <=[ {ref} (b1) type [int ] typdecl at <built-in>:0
$RE_structref_line   = qr"(?:([0-9]+)\s*<=\[\s+(\{ref\})\s+\(([a-zA-Z_0-9]+)\)\s+type $RE_balanced_squarebrackets typdecl at: ([^:]*):([0-9]+)\s*$)";

#29292 <=[ (ref) (func)  decl at test.c:3  type [int  (/* ??? */)] typdecl at: <built-in>:0 
#$RE_reffunc_line         = qr"(?:([0-9]+)\s*<=\[\s+\(ref\)\s+\(([a-zA-Z_0-9]+)\)\s+decl at ([^:]*):([0-9]+)\s+type $RE_balanced_squarebrackets typdecl at: ([^:]*):([0-9]+)\s*$)";

#call (cc1.real):[ /opt/gcc-4.2.1/bin/../libexec/gcc/i486-slackware-linux/4.2.1/cc1.real -quiet -iprefix /opt/gcc-4.2.1/bin/../lib/gcc/i486-slackware-linux/4.2.1/ test.c -quiet -mtune=i486 -march=i486 -auxbase test -o /tmp/ccu3c03L.s -fparse-info=test.c.pinfo -fparse-id=1]=1
$RE_parsedef_line   = qr"(?:call $RE_balanced_smothbrackets:$RE_balanced_squarebrackets(?:=([0-9]+))?$)";


#444(@4) <=[ decl  [int  (/* ??? */):f1]] at [test.c:3]-[test.c:5] type [int  (/* ??? */)] decl at: <built-in>:0
$RE_decl_line        = qr"(?:([0-9]+)\(\@([0-9]+)\)\s*<=\[[ \[\(]decl[ \]\)] $RE_balanced_squarebrackets\s+at\s+$RE_balanced_squarebrackets-$RE_balanced_squarebrackets\s+type\(\@([0-9]+)\)\s+$RE_balanced_squarebrackets\s+decl\(\@([0-9]+)\) at: ([^:]*):([0-9]+)\s*$)";


$href_noref = " href=\"#any_URL\" ";

$recspan_spanu = "<span id=\"T¶re_id¶u\" class=\"macrou\"><a href=\"javascript:expand('¶re_id¶')\" border=0>¶re_n¶</a>¶re_b¶</span>";
$recspan_spane = "<span id=\"T¶re_id¶e\" class=\"macroe\"><a href=\"¶re_def¶\" border=0>¶re_n¶</a>¶re_b¶<a href=\"javascript:expand('¶re_id¶')\" border=0>[&lt;]</a></span>";

$repspan_span  = "<span class=\"macrou\">¶re_b¶</span>";
$repspan_spanu = "<a $href_noref onclick=\"top[document.htmltagid].repf_þre_midþe(this)\" border=0>¶re_n¶</a>¶re_b¶";
$repspan_spane = "¶re_mref¶¶re_n¶</a>¶re_b¶<a $href_noref onclick=\"top[document.htmltagid].repf_þre_midþu(this)\" class=\"close\" border=0>[&lt;]</a>";
#<a href=\"¶re_def¶\" class=\"def\" border=0>

$repxmlspan_span  = "<span id=\"T¶re_id¶ue\" class=\"macrou\">¶re_b¶</span>";
$repxmlspan_spanu = "<a $href_noref onclick=\"top[document.htmltagid].xml.replaceXMLspan(this,'¶re_xmlfile_e¶','T¶re_id¶e')\" border=0>¶re_n¶</a>¶re_b¶";
$repxmlspan_spane = "¶re_mref¶¶re_n¶</a>¶re_b¶<a $href_noref onclick=\"top[document.htmltagid].xml.replaceXMLspan(this,'¶re_xmlfile_u¶','T¶re_id¶u')\" class=\"close\" border=0>[&lt;]</a>";
#<a href=\"¶re_def¶\" class=\"def\" border=0>

$repajaxspan_span  = "<span id=\"T¶re_id¶ue\" class=\"macrou\">¶re_b¶</span>";
$repajaxspan_spanu = "<a $href_noref onclick=\"top[document.htmltagid].ajax.replaceAJAXspan(this,'¶re_xmlfile_e¶','T¶re_id¶e')\" border=0>¶re_n¶</a>¶re_b¶";
$repajaxspan_spane = "¶re_mref¶¶re_n¶</a>¶re_b¶<a $href_noref onclick=\"top[document.htmltagid].ajax.replaceAJAXspan(this,'¶re_xmlfile_u¶','T¶re_id¶u')\" class=\"close\" border=0>[&lt;]</a>";
#<a href=\"¶re_def¶\" class=\"def\" border=0>


$divop = "<a href=\"javascript:top[document.htmltagid].togglevisible('¶re_id¶')\" border=0>¶re_line¶</a>";
$divb0 = "<div id=\"T¶re_id¶\" class=\"¶re_class¶\" style=\"¶re_style¶\">";
$divb1 = "</div>"; 

$repxmldiv_div  = "<div id=\"D¶re_id¶ue\" class=\"fincmarku\" style=\"¶re_style¶\">¶re_b¶</div>";
$repxmldiv_divu = "¶re_ln¶<a $href_noref onclick=\"top[document.htmltagid].xml.replaceXMLdiv(this,'¶re_xmlfile_e¶','D¶re_id¶e')\" title=\"top[document.htmltagid].xml.replaceXMLdiv(this,'¶re_xmlfile_e¶','D¶re_id¶e')\"                   border=0>¶re_n¶</a>¶re_b¶";
$repxmldiv_dive = "¶re_ln¶<a $href_noref onclick=\"top[document.htmltagid].xml.replaceXMLdiv(this,'¶re_xmlfile_u¶','D¶re_id¶u')\" title=\"top[document.htmltagid].xml.replaceXMLdiv(this,'¶re_xmlfile_u¶','D¶re_id¶u')\" class=\"close\" border=0>¶re_n¶</a><div class=\"fince\" style=\"¶re_style¶\" >¶re_b¶</div>";

$repajaxdiv_div  = "<div id=\"D¶re_id¶ue\" class=\"fincmarku\" style=\"¶re_style¶\">¶re_b¶</div>";
$repajaxdiv_divu = "¶re_ln¶<a $href_noref onclick=\"top[document.htmltagid].ajax.replaceAJAXdiv(this,'¶re_xmlfile_e¶','D¶re_id¶e')\" title=\"top[document.htmltagid].ajax.replaceAJAXdiv(this,'¶re_xmlfile_e¶','D¶re_id¶e')\"                   border=0>¶re_n¶</a>¶re_b¶";
$repajaxdiv_dive = "¶re_ln¶<a $href_noref onclick=\"top[document.htmltagid].ajax.replaceAJAXdiv(this,'¶re_xmlfile_u¶','D¶re_id¶u')\" title=\"top[document.htmltagid].ajax.replaceAJAXdiv(this,'¶re_xmlfile_u¶','D¶re_id¶u')\" class=\"close\" border=0>¶re_n¶</a><div class=\"fince\" style=\"¶re_style¶\" >¶re_b¶</div>";


$struct_divo = "<div id=\"¶re_id¶\" style=\"display:none;\" >";
$struct_divc = "</div>";
if ($OPT{'dbgtool'}) {
$struct_divo = "<div id=\"¶re_id¶\" style=\"display:block;\" >";
}

$stash_open = 
$RE_string =                     qr{"((?:\\.|[^\\"])*)"};
$RE_string_one =                 qr{'((?:\\.|[^\\'])*)'}; #"

$mutiref = "<a href=\"¶re_href¶\" border=0>¶re_line¶</a>";

%files = ();
$ftopstack    = {            'f'=>$outputtop };
$fidxstack    = {            'f'=>$outputidx };
$structfstack = {'fid' => 0, 'l'=>1,'f'=>"<struct>",'html' => "", '_l' => 1, b=>[]};
$bstack       = {'fid' => 1, 'l'=>1,'f'=>"<base>",  'html' => "", '_l' => 1, b=>[]};
$bstackf      = {'fid' => 2, 'l'=>1,'f'=>"<in>",    'html' => "", '_l' => 1, b=>[]};
$_fb = 1;
$$bstack{'inc'} = [$bstackf];
@fstack = ($structfstack,$bstack,$bstackf);
@funcstack = ();
%fid = ('0'=>$structfstack,'1'=>$bstack,'2'=>$bstackf);
$fid = 2;
%ftofid = ();
%ftofidline = ();
%linerefs = ();
%linerec = ();
%gctx = ('d'=>1,'id'=>10,'jid'=>1, 'onload'=>'', 'xml' => '', 'skip' => 0);
%links = ();
$linksid = 1;

sub pushlinerec {
    my ($f,$startline,$endline, $struct) = @_;
    $linerec{$f} = [] if(!exists($linerec{$f}));
    my $sz = scalar(@{$linerec{$f}}); my $pos = $sz-1;
    $$struct{'frec'} = [$f,$startline,$endline];
    while($pos>0) {
        if ($endline >= $linerec{$f}[$pos][1]) {
            $pos++;
            last;
        }
        $pos--;
    }
    $pos = 0 if ($pos < 0);
    splice(@{$linerec{$f}},$pos,0,[$startline,$endline, $struct]);
}

@refs = ();

sub unregisterref {
    my ($ref) = @_;
    my ($refdfile,$refdline) = @$ref{'refdfile','refdline'};
    if (exists($linerefs{$refdfile}{$refdline})) {
	my $a = $linerefs{$refdfile}{$refdline};
	for (my $i = 0; $i < scalar(@{$a});$i++) {
	    if ($$a[$i] == $ref) {
		splice(@$a,$i,1);
		return 1;
	    }
	}
    }
    return 0;
}

sub registerref {
    my ($ref) = @_;
    my ($refdfile,$refdline) = @$ref{'refdfile','refdline'};
    if (exists($ftofidline{$refdfile}{$refdline})) {
        $$ref{'refdfid'} = $ftofidline{$refdfile}{$refdline};
    } else {
        $$ref{'refdfid'} = $ftofid{$refdfile};
    }

    $linerefs{$refdfile}{$refdline} = [] if (!exists($linerefs{$refdfile}{$refdline}));
    push(@{$linerefs{$refdfile}{$refdline}},$ref);
}

$refid = 1;
%refid = ();
sub idref {
    foreach my $fn (keys %linerefs) {
        my $f = $linerefs{$fn};
        foreach my $ln (keys %$f) {
            my $la = $$f{$ln};
            $refid{$fn}{$ln} = $refid;
            foreach my $ref (@$la) {
                $$ref{'refid'} = $refid;
            }
            $refid++;
        }
    }
}


sub creategotolink_js {
    my ($id,$ref) = @_;
    my ($_refid,$refdfile,$refdline,$refdfid) = @$ref{'refid','refdfile','refdline','refdfid'};
    $_refid = -1 if (!defined($_refid));
    return "top[document.htmltagid].path.gotolocationopen(this,'$id','$refdfid',$_refid);";
    #return "<a ¶re_toolclass¶ $class $onmouseover href=\"#$_refid\" name=\"$id\" onclick=\"top[document.htmltagid].path.gotolocationopen(this,'$id','$refdfid',$_refid)\" title=\"onclick:top[document.htmltagid].path.gotolocationopen(this,'$id','$refdfid',$_refid)\" >";
}

sub gotolink {
    my ($id,$ref,$class) = @_;
    my ($fstack,$ref) = @_;
    $class = "class=\"$class\"" if ($class);
    my $g = creategotolink_js($id,$ref);
    my ($_refid,$refdfile,$refdline,$refdfid) = @$ref{'refid','refdfile','refdline','refdfid'};
    $_refid = -1 if (!defined($_refid));
    return "<a ¶re_toolclass¶ $class $onmouseover href=\"#$_refid\" name=\"$id\" onclick=\"$g\" title=\"onclick:$g\" >";
}

sub maprefid {
    my ($fstack,$ref) = @_;
    my ($_refid,$refdfile,$refdline,$refdfid) = @$ref{'refid','refdfile','refdline','refdfid'};
    my $onmouseover = "";
    my $id = $refid++;

    if (exists($$ref{'tooltip'})) {
        my @a = ();
        foreach my $tooltip (@{$$ref{'tooltip'}}) {
            my $id = $$tooltip{'id'};
            if (ref($tooltip) eq 'STRUCT') {
                $id = "'S${id}'";
            } elsif (ref($tooltip) eq 'TYPDEF') {
                $id = "'T${id}'";
            } elsif (ref($tooltip) eq 'DECL') {
                $id = "'D${id}'";
            } elsif (ref($tooltip) eq 'MACRO') {
                $id = "'M${id}'";
            } elsif (ref($tooltip) eq 'LINK') {
                $id = "'L".$$tooltip{'n'}."'";
            } else {
		die("Tooltip type \"".ref($tooltip)."\" unknown");
	    }
            if ($style_xml || $style_ajax) {
		if (ref($tooltip) eq 'LINK' && $style_xml) {
		    push(@a,"'$exportdb'","'SYM_".$$tooltip{'n'}."'");
		} elsif (ref($tooltip) eq 'LINK' && $style_ajax) {
                    my $f = gettoolxmlfilename($id);
		    push(@a,"'$f'",$id);
		} else {
		    my $f = gettoolxmlfilename($id);
		    push(@a,"'$f'",$id);
		}
            } else {
                push(@a,$id);
            }
        }
        if ($style_xml) {
            return "<a ¶re_toolclass¶ href=\"javascript:top[document.htmltagid].xml.showxmltool('--xmlid--$id',".join(",",@a).");\" id=\"A--xmlid--$id\" title=\"top[document.htmltagid].xml.showxmltool('--xmlid--$id',".join(",",@a).");\" >";
        } elsif ($style_ajax) {
            return "<a ¶re_toolclass¶ href=\"javascript:top[document.htmltagid].ajax.showajaxtool('--xmlid--$id',".join(",",@a).");\" id=\"A--xmlid--$id\" title=\"top[document.htmltagid].ajax.showajaxtool('--xmlid--$id',".join(",",@a).");\" >";
        } else {
            return "<a ¶re_toolclass¶ href=\"javascript:top[document.htmltagid].span.showtool('--xmlid--$id',".join(",",@a).");\" id=\"A--xmlid--$id\" title=\"top[document.htmltagid].span.showtool('--xmlid--$id',".join(",",@a).");\" >";
        }
    }
    
    return "<a>";
    if ($refdfid == $$fstack{'fid'}) {
	return "<a ¶re_toolclass¶ href=\"#$_refid\" $onmouseover >";
    }
    return gotolink($id,$ref);
}

# ------------- file functions ---------------

sub dir2url {
    my ($n) = @_;
    #print("dir2url(".$n.")=>");
    if ($onserver) {
	$n = abs_path($n) if (!($n =~ /^\//));
	$n =~ s/^$serverroot// or die("\"$n\" is not in server $serverroot\n");
	#print(" root: $serverroot $n ");
	$n = "/$n" if (!($serverprefix =~ m/\/$/ || $n =~ m/^\//));
	$n = $serverprefix.$n;
    }
    
    return $n;
}


sub rel2outdir {
    my ($fn) = @_;
    if (length($outputdir)) {
        if (substr($fn,0,length($outputdir)) eq $outputdir) {
            $fn = substr($fn,length($outputdir));
            $fn =~ s/^\///;
        }
    }
    return $fn;
}

%map2url = ();
sub map2url {
    my ($f,$rel) = @_;
    my $fn = $$f{'f'}; # original filename
    #dirname($fn)."/".
    $fn = $$f{'url'}    if (exists($$f{'url'})); # already a mapping specified 
    $fn = $map2url{$fn} if(exists($map2url{$fn})); # global mapping
    if ($fn eq '<base>' && !$style_multi) { # for '<base>' use the -o option
	$fn = $output;
    }
    if ($rel && length($outputdir)) {
        $fn = rel2outdir($fn);
	
	if (substr($fn,0,length($outputdir)) eq $outputdir) {
            $fn = substr($fn,length($outputdir));
            $fn =~ s/^\///;
        }
    }
    return $fn;
}

sub getxmlfilename {
    my ($fstack,$id) = @_;
    my $fid = "".$$fstack{'fid'};
    
    #print ($id."\n");
    #if (!$style_xmlmultifile) {
	##return filename(map2url($fstack).".xml");
        #return "ære__fid_".$$fstack{'fid'}."æ";
    #}
    $id =~ s/'//g; #'
    #return filename(map2url($fstack).".${id}.xml");
    return "ære__fid_".$$fstack{'fid'}."_${id}æ";
}

sub gettoolxmlfilename {
    my ($id) = @_;
    return getxmlfilename($structfstack,$id);
}


sub fileline {
    my ($n) = @_;
    $n =~ s/^["\s]*//;
    $n =~ s/["\s]*$//;
    if ("<built-in>" eq $n) {
        return [];
    } elsif ("<command-line>" eq $n) {
        return [];
    } else {
        print ("Loading file $n\n") if ($OPT{dbgfile});
        my $m = readfile($n);
        my @m = split("\n",$m); 
        return [ map { [$_] } @m ];
    }
}

sub fileindex {
    my ($isroot,$fstack,$ctx) = @_;
    my ($f,$fid,$fl,$u) = @$fstack{'f','fid','fl','u'};
    my @inc = @{$$fstack{'inc'}};
    my $html = "";
    my @f = split("\/",$f);
    my $fn = $f[$#f];
    my $link = "javascript: { top[document.htmltagid].path.checkfileother('\@'); top[document.htmltagid_other].path.gotolocation('F${fid}'); }";
    $f = "<a class=\"idx\" href =\"$link\" title=\"Line: $fl file: $f id: ${fid}\">$fn</a>";
    my $c = "<span class=\"idx\"><a class=\"idx\" href=\"javascript:{checkfile('\@');top[document.htmltagid].togglevisible('${fid}');}\" ><span class=\"idx\" id=\"TS${fid}\">[".($isroot?"-":"+")."]</span></a>$f</span>";
    $html .= "<div id=\"TP${fid}\" class=\"selidx\"></div>";
    $html .= "<div id=\"TV${fid}\" class=\"selidx\">$c</div>";
    $$ctx{'idx'}{$fid} = $c;
    $$ctx{'link'}{$fid} = $link;
    $$ctx{'linkopen'}{$fid} = "top[document.htmltagid].path._opencloseother(\"${fid}\"";
    $$ctx{'name'}{$fid} = $fn;
    my $off = 1;
    if (1 || scalar(@inc)) {
        $html .= "<div id=\"TI${fid}\" class=\"idx\">";
        if (!$isroot) {
            $$ctx{'onload'} .= "hide('${fid}');";
        }
        foreach my $inc (@inc) {
            $$ctx{'pre'}{$$inc{'fid'}} = $$inc{'fl'} - $off;
            $html .= fileindex(0,$inc,$ctx);#."\n";
            $off = $$inc{'fl'} + 1;
        }
        $html .= "<div id=\"TE${fid}\" class=\"selidx\"></div>";
        $html .= "</div>";
    } else {
        #$html .= "<span class=\"idx\">->$f</span>";
    }
    $$ctx{'post'}{$fid} = $u - $off;
    return $html;
}

# ------------- file stack ---------------

sub addchildstack {
    my ($f,$a) = @_;
    $$f{'inc'} = [] if (!exists($$f{'inc'}));
    push(@{$$f{'inc'}},$a);
    #print($$f{'fid'}.":".join(",",map  { $$_{'fid'} } @{$$f{'inc'}})."\n") if ($OPT{dbgf});
}

sub replacechild {
    my ($f,$a,$b) = @_;
    for (my $i = 0; $i < @{$$f{'inc'}}; $i++) {
	if ($$f{'inc'}[$i]{'fid'} ==  $$a{'fid'}) {
	    $$f{'inc'}[$i] = $b;
	    return 1;
	}
    }
    die("Couldnt find child with id ".$$a{'fid'}." in ".$$f{'fid'}.", try to replace with ".$$b{'fid'}."\n");
}

sub fileblock_fromname {
    my ($n) = @_;
    my @f = grep { $fid{$_}{'f'} eq $n } keys %fid;
    return $fid{$f[0]};
}

sub fileblock {
    my ($f,$l,$p) = @_;
    my $pid = -1;
    $pid = $$p{'fid'};
    #print ($pid.":".$$p{'f'}."\n");
    $ftofid{$f} = $fid;
    my $b = bless { 'fid' => $fid, 'pid' => $pid, 'typ' => 'fopen', 
                    'f' => $f ,'d' => (scalar(@fstack)+1), 
                    'l' => $l, '_l' => $l, 'p' => [], 'skip' => [],
                    'u' => 2 },'BLOCK';
    $fid{$fid++} = $b;
    if (length($f)) {
	$$b{'b'} = fileline($f);
        $f =~ s/^["\s]*//;
        $f =~ s/["\s]*$//;
        if ("<built-in>" eq $f) {
            $$b{'b'} = [];
        } elsif ("<command-line>" eq $f) {
            $$b{'b'} = [];
        } else {
            print ("Loading file $f\n") if ($OPT{dbgfile});
            my $m = readfile($f);
	    $m =~ s/\r//g;
            my @m = split("\n",$m);
            $$b{'moa'} = [@m];
            my $o = 0;
            my @mo = map { my $d = $o; $o += length($_) + 1; $d } @m;
            $$b{'m'} = $m;
            $$b{'mo'} = [@mo];
            $$b{'b'} = [ map { [$_] } @m ];
            $$b{'u'} = scalar(@m) + 1;
            # du levande
        }
    }
    my $o = $f;
    if ($f eq '<base>') {
        $o = $output; 
    } else {
        $o = $output."_".$f; 
    }
    #$o = basename($o);
    $o =~ s/[\/\.]/_/g;
    $$b{'url'} = $outputdir."/".$o;
    return $b;
}

sub create_jsopen {
    my ($f) = @_;
    my ($fn,$fid,$pid) = @$f{'f','fid','pid'};
    my @r = (); my $g= undef; my $r = undef;
    @r = create_jsopen($fid{$pid}) if ($pid != 0);
    if(($style_multi) && ($style_xml||$style_ajax)) {
	#$g = "/*$fn:*/gotolocation('D${fid}ue'";
        if ($style_xml) {
            $r = "/*$fn:*/top[document.htmltagid].xml.replaceXMLpath('".$$f{'xmlfile'}."','D${fid}e','D${fid}ue'" if(exists($$f{'xmlfile'}));
        } elsif ($style_ajax) {
            $r = "/*$fn:*/top[document.htmltagid].ajax.replaceAJAXpath('".$$f{'xmlfile'}."','D${fid}e','D${fid}ue'" if(exists($$f{'xmlfile'}));
        }
    } else {
	$r = "/*$fn:*/top[document.htmltagid].toggleshow('${fid}'";
    }
    return grep { defined($_) } (@r,$g,$r);
}

sub create_jsclose {
    my ($f) = @_;
    my ($fn,$fid,$pid) = @$f{'f','fid','pid'};
    my @r = (); my $g= undef; my $r = undef;
    if(($OPT{'style'} =~ /multipage/) && ($style_xml||$style_ajax)) {
	if ($style_xml) {
            $r = "/*$fn:*/top[document.htmltagid].xml.replaceXMLpath('".$$f{'xmlfile'}."','D${fid}u','D${fid}ue'" if(exists($$f{'xmlfile'}));
        } elsif ($style_ajax) {
            $r = "/*$fn:*/top[document.htmltagid].ajax.replaceAJAXpath('".$$f{'xmlfile'}."','D${fid}u','D${fid}ue'" if(exists($$f{'xmlfile'}));
        }
    } else {
	$r = "/*$fn:*/top[document.htmltagid].togglehide('${fid}'";
    }
    return grep { defined($_) } (@r,$g,$r);
}

sub collectprepends {
    my ($f) = @_;
    if (exists($$f{'prepend'})) {
	return ($f,collectprepends($$f{'prepend'}));
    }
    return ($f);
}

sub collectpids {
    my ($f,$r) = @_;
    if ($f != $r && exists($$f{'pid'})) {
	return ($f,collectpids($fid{$$f{'pid'}},$r));
    }
    return ($f);
}

sub collectcids {
    my ($f,$i) = @_;
    return () if (exists($$i{$$f{'fid'}}));
    $$i{$$f{'fid'}} = 1;
    my @r = ($f);
    foreach my $c (@{$$f{'inc'}}) {
        push(@r,collectcids($c,$i));
    }
    return (@r);
}

sub pushfilerenameblock {
    my ($f,$l) = @_;
    my $p = $fstack[$#fstack-1];
    my $b = fileblock($f,$l,$p);
    $$b{'typ'} = 'frename';

    $fstack[$#fstack]{'appand'} = $b;
    $fstack[$#fstack]{'renamed'} = 1;
    $$b{'prepend'} = $fstack[$#fstack];
    
    
    replacechild($p,$fstack[$#fstack],$b);
    $fstack[$#fstack] = $b;

    return $b;
}

sub pushfileopenblock {
    my ($f) = @_;
    my $b = fileblock($f,1,$fstack[$#fstack]);
    addchildstack($fstack[$#fstack],$b);
    push(@fstack,$b);
    return $b;
}


@tokid = ();
%mid = ();
%refs = ();
@frefs = ();
%structs = ();
%_structs = ();
%typedefs = ();
%structsid = ();

sub instantiate_ref {
    my ($b,$l) = @_;
    die ("Unknown format of path: $b") if (!($b =~ /[\[\(]([0-9\.]+)[\]\)]\.([0-9\.]+)/));
    my ($p,$id) = ($1,$2);
    my @_p = ($p);
    if ((!$norec) && exists($mmdom{$p})) {
        @_p = keys %{$mdom{$mmdom{$p}}};
    } 
    foreach my $p (@_p) {
        my @p = split('\.',$p);
        my @ids = collectpp($id,{});
        for (my $i = 0; $i < scalar(@p); $i++) {
            my $p = join(".",@p[0..$i]);
            foreach my $_id (@ids) {
                $refs{"(${p}).$_id"} = $l;
                $refs{"[${p}].$_id"} = $l;
            }
        }
    }
}

$htmltag_html_linkid = $OPT{'linkid'} || 0;

$htmltag_html_fid = 0;
if ($b[0] =~ $RE_parsedef_line) {
    my ($prog,$args,$id) = ($1,$2,$3);
    $id = 0 if (!$id);
    $htmltag_html_fid = $id;

    if ((!exists($OPT{'fid'}) && $args =~ m/-fhtmltag-fid\s*=\s*([0-9]+)/)) {
	$htmltag_html_fid = $1;
    }
    if ((!exists($OPT{'linkid'})) && ($args =~ m/-fhtmltag-linkid\s*=\s*([0-9]+)/)) {
	$htmltag_html_linkid = $1;
    }
} 
if (exists($OPT{'fid'})) {
    $htmltag_html_fid = $OPT{'fid'} || 0;
}
if (exists($OPT{'fidrand'})) {
    $htmltag_html_fid = int(rand(10000000));
}

$re_sajax_fid = $htmltag_html_fid;

sub reload_filename {
    my ($n) = @_;
    return "_reload_${n}.html";
}

print("Fid: $htmltag_html_fid Linkid: $htmltag_html_linkid \n") if ($OPT{'verbose'} && !$OPT{'quite'});

for (my $bidx = 0; $bidx < scalar(@b); $bidx++) {
    my $l = $b[$bidx];
    if ($l =~ $RE_link_line) {
	$links{$1} = {'n' => $1, 'e' => $2, 'id' => $linksid++, 'html' => "link to <a href=\"".reload_filename($1)."\">$1</a>" };
	print("$1 : $2\n") if ($OPT{'dbglink'});
    } 
}

my $last_anchor = undef;
for (my $bidx = 0; $bidx < scalar(@b); $bidx++) {
    my $l = $b[$bidx];
    my $fstack = $fstack[$#fstack];
    
    #print("Process $l\n");
    
    if ($l =~ $RE_token_line) {
        # a token visible to the compiler. A optional $path depicts the macro source if
        # it is expanded by a macro call.
        # 429:	c1:	TOK	[10
	my ($line,$id,$path,$typ,$tok) = ($1,$2,$3,$4,$5);
	next if ($typ eq 'PAD');
        
	#print("=>token Tok $id: $path: $tok\n");
	
	if (length($path) && $path ne '=>' && (! ($path =~ /\#/))) { #$path ne '=>#' && $path ne '#' ) {
	    
	    #print("Tok: next\n");
	    
	    $mid{$id} = [] if (!exists($mid{$id}));
	    push(@{$mid{$id}},$path.".".$id);
            
            next;
	}
        if ($typ eq 'CMT')  {
            my $cmttok = $tok;
            if (my $lcnt = ($cmttok =~ s/\\n/\n/g)) {
                my $ln = $$fstack{'l'};
                my $o = $$fstack{'mo'}[$ln-1];
                    
                $$fstack{'l'} += $lcnt;
                push(@l,join("",("\n") x ($lcnt)));
                
                #my $i = index($fstack[$#fstack]{'m'},$cmttok,$o);
                #die("Mismatch in comment insertion tag:\n".quote($cmttok,30)."\nori($o):\n".quote(substr($fstack[$#fstack]{'m'},$o,length($cmttok)),30)."\n") if ($i == -1);
                
                
            }
        } else {            
            if ($line > $$fstack{'l'}) {
                push(@l,join("",("\n") x ($line - $$fstack{'l'})));
                $$fstack{'l'} = $line;
            }
            my $h = { 'typ' => $typ, 'tok' => $tok, 'id' => $id, 'line' => $line };
	    my $doadd = 1;
            if ($path =~ s/#//g) {
		$$h{'dir'} = 1;
		if (($path =~ /[\[\(]([0-9\.]+)[\]\)]/)) {
		    # maxro expansion inside directive. Register id in macro domain 
		    my $_p = $1;
		    $mmid{$id} = $_p;
                    $doadd = 0;
		}
		$id{$id} = $#l + 1;
		#print ("Re $id:".$id{$id}."\n");
		
	    } elsif ($id) {
#
##define a c
#
##define c(v1) d(v1)
#
##define d(v) int v 
#
#a(a0);
#a(b0);
# 
# In this example 'a' will be replaced to 'c'. Because 
# will aprear as anchor 2 times. Therrefore "Token $id already exists" message
# should be put out. However we let $id{$id} be overwritten so that the latest is found.
# todo: operate on arrays of registered ids.
#
#...
#8@387:=>:TOK    [a
#        <=387   (1)     #       NAME    [a](@102)#tmp/1_file1.c:2#a c
#        365     [1]             |       TOK     [c
#8@391::PAD      [
#8@365:=>:TOK    [c
#8@0::GRP        [(
#8@393:  v1:     TOK     [a0
#8@0::GRP        [)
#        <=365   (2)     #       NAME    [c](@103)#tmp/1_file1.c:4#c(v1) d(v1)
#        0       (2)     #       GRP     [(
#...
#8@407::GRP      [;
#384(@1) <=[ decl  [int :a0] at [tmp/1_file1.c:8]-[tmp/1_file1.c:8] type(@0) [int ] decl(@0) at: <built-in>:0
#9@408:=>:TOK    [a
#        <=408   (4)     #       NAME    [a](@102)#tmp/1_file1.c:2#a c
#        365     [4]             |       TOK     [c
#9@412::PAD      [
#9@365:=>:TOK    [c
#9@0::GRP        [(
#9@414:  v1:     TOK     [b0
#9@0::GRP        [)
#        <=365   (5)     #       NAME    [c](@103)#tmp/1_file1.c:4#c(v1) d(v1)
#... 

		$last_anchor = $#l + 1 if ($path eq '=>');
		
		if (exists($id{$id})) {
		    print ("Token $id already exists, line ".($bidx+1)."\n") if ($OPT{'dbgexid'});
		    $idm{$id} = [ $id{$id} ] if (!exists($idm{$id}));
		    push(@{$idm{$id}},$#l + 1);
		} 
		$id{$id} = $#l + 1;
                $line{$id} = [$cfile,$cline];
		
                print (" id register $id \n")  if($OPT{'dbgidreg'});
            }
            # $doadd clause was added so that a 23@23:[20]#:...  directive expansion don't end up in the token line. Might be incorrect.
            # on problems remove this test.
            if ($doadd) { 
                
                push(@l,$h) ;
                $$fstack{'p'}[$line-1] = [] if (!exists($$fstack{'p'}[$line-1]));
		my $cpos = scalar(@{$$fstack{'p'}[$line-1]});
		$h{'cp'} = $cpos;
                push(@{$$fstack{'p'}[$line-1]},$h);
            }

            if ($gctx{'skip'} == 0) {
                $ftofidline{$$fstack{'f'}}{$line} = $$fstack{'fid'};
            }
        }
    } elsif ($l =~ $RE_mcall_line) {
        # inserted by preprocessor
        # a macrocall. Not visible to compiler but part of the pinfo stream 
	# and matched against the tokenized source stream. A special case is
	# when a 0-arg macro expansion is used as a name for a x-arg expansion: 
	    ##define a c
            ##define c(v1) d(v1)
            ##define d(v) int v 
	    #a(a0);
#>#7@387:=>:TOK	[a
# #	<=387	(1)	#	NAME	[a](@102)#tmp/1_file1.c:1#a c
# #	365	[1]		|	TOK	[c
# #7@390::PAD	[
#>#7@365:=>:TOK	[c
# #7@0::GRP	[(
# #7@392:	v1:	TOK	[a0
# #7@0::GRP	[)
	# This will yeald [a,c,...] in the pinfo stream while in the
	# source stream it is [a,...]. The 'c' should really be marked
	# seperatly by gcc but until then we handle this here.
	# 18@421: b:      TOK     [b
	
	#printf("=>macrocall\n");
	
	my ($line,$id,$op,$typ,$tok) = ($1,$2,$3,$4,$5);
	my $h = { 'typ' => $typ, 'tok' => $tok, 'op' => $op, 'id' => $id };
	push(@l,$h);
        
        $$fstack{'p'}[$line-1] = [] if (!exists($$fstack{'p'}[$line-1]));
        push(@{$$fstack{'p'}[$line-1]},$h);
        
        if ($gctx{'skip'} == 0) {
            $ftofidline{$$fstack{'f'}}{$line} = $$fstack{'fid'};
        }

    } elsif ($l =~ $RE_macro_line ) {
        # a macro expansion trace. The $path depicst:
        # (..) unexpanded invaocation
        # [..] expanded result (possibly with other macro invaocations)
	# 438	[2.3]		.b:	PAD	[
	my ($id,$path,$op,$typ,$tok) =  ($1,$2,$3,$4,$5);
	
	next if ($typ eq 'PAD');
	if (($op) eq 'NAME') {
        }
        my $pid = $path;
	$pid =~ s/[\(\[\]\)]//g;
	if (!exists($ml{$pid})) {
	    $ml{$pid} = [] ;
	    push(@ml,$pid);
	}
	push(@{$ml{$pid}},$l);

	# this pid registration is later redone by macro processing
	# it is done here to be able to handle linking inside macros
	my $pid = $path.".".$id;
	if (!($id =~ /^<=([0-9]+)/)) {
	    $pid{$id} = [] if (!exists($pid{$id}));
	    push(@{$pid{$id}},$pid);
	    #print("Register $pid with token $id\n");
	}
	
        #a reference to a token can spread across macro args and invocations
        #this code keeps track of a macro tree, called macro domain. 
        #The instantiate_ref() function uses this information to 
        #assign references to all occurences of a token in a macro domain
        my $_p = $path;
        $_p =~ s/[\(\[\)\]]//g;
	if (!$norec) {
	    if ($id =~ /^<=([0-9]+)/) {
		my ($_id) = ($1);
		#print ("$_p<\n");
		if (exists($id{$_id}) && $id{$_id} != -1) {
		    # anchor is toplevel token. Assign new macro domain.
		    $mmdom{$_p} = $mmdomid;
		    $mmdomid++;
		} else {
		    if (exists($id{$_id}) && $id{$_id} == -1) {
			# anchor is a "##" paste token 
			die("Unknown paste token $_id") if (!exists($ppid{$_id}));
			my ($l0,$l1,$p) = @{$ppid{$_id}};
			$mmdom{$_p} = $mmdom{$p};
		    } else {
			# propagate the anchor's macro domain  
			print ("Token $_id in macro references nonexisting macrotoken\n") if (!exists($mmid{$_id}));
			$mmdom{$_p} = $mmdom{$mmid{$_id}};
		    }
		}
		$mdom{$mmdom{$_p}}{$_p} = 1;
	    } else {
		print ("mid register $id \n") if($OPT{'dbgidreg'});
		$mmid{$id} = $_p;
	    }
	}
        
	    
    } elsif ($l =~ $RE_ref_line || $l =~ $RE_ref_short_line) {
        # inserted by c-decl.c and c-typcheck.c
        # a previously declared variable is referenced (i.e. a = 1;). Specifies the declaration position
        # and the type declaratoin position
        # 441 <=[  ref  (a)  decl at test.c:8  type [int ] typdecl at: <built-in>:0
	my ($id,$declid,$reftyp,$refex,$refn,$refdfile,$refdline,$typ, $typdfile,$typdline) = ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10);
	my $ref = { 'refdfile' => $refdfile, 'refdline' => $refdline, 'typ' => $typ, 'typdfile' => $typdfile, 'typdline' => $typdline, 'n' => $refn};
        registerref($ref); push(@refs,$ref);
        if (exists($id{$id})) {
	    if ($OPT{'dbgref'}) {
		print("$reftyp$refex : $id <= \"$refn\"\@$refdfile:$refdline typ \"$typ\"\@$typdfile:$typdline declid:\@$declid".( exists($decls{$declid}) ? " (declared)" : "(not declared)")."\n") ;
	    }
	    $l[$id{$id}]{'ref'} = $ref;
        } elsif (exists($mid{$id})) {
            my $mp = $mid{$id}[scalar(@{$mid{$id}})-1];
	    if ($OPT{'dbgref'}) {
		print("$reftyp : (mid[$id]=$mp) <= \"$refn\"\@$refdfile:$refdline typ \"$typ\"\@$typdfile:$typdline declid:\@$declid".( exists($decls{$declid}) ? " (declared)" : "(not declared)")."\n") ;
	    }
            instantiate_ref($mp,$ref);
	}
	if ($reftyp eq '(ref)') {
	    push(@frefs,$ref);
	    print ("=>Call func $refn from funcstack [".join(" ",@funcstack)."]\n") if ($OPT{'dbgexpi'});
	    $do_export_call{$funcstack[$#funcstack]} = [] if (!$do_export_call{$funcstack[$#funcstack]});
	    push(@{$do_export_call{$funcstack[$#funcstack]}}, $refn) if (!(grep { $_ eq $refn } @{$do_export_call{$funcstack[$#funcstack]}}));
	    
	}
	my $toole = bless { 'n' => $refn, 'id' => $refn  },'LINK';
	$$ref{'tooltip'} = [] if (!exists($$ref{'tooltip'}));
	push(@{$$ref{'tooltip'}}, ($toole));
	
	if (exists($decls{$declid})) {
	    #add a tooltip to $ref (that is registered at token's 'ref')
	    #the content should be $decls{$declid} 
	    my $tool = bless { 'id'=>$declid },'DECL';
            
	    $$ref{'tooltip'} = [] if (!exists($$ref{'tooltip'}));
            push(@{$$ref{'tooltip'}}, ($tool));
	    
	    if (exists($links{$refn}) && $links{$refn}{'e'} eq 'e') {
		$$ref{'tooltip'} = [] if (!exists($$ref{'tooltip'}));
		push(@{$$ref{'tooltip'}}, bless { 'id'=>$links{$refn}{'id'}, 'n' =>$links{$refn}{'n'} },'LINK');
		$$tool{'extern'} = 1;
	    }
        } else {
	    if (exists($links{$refn}) && $links{$refn}{'e'} eq 'e') {
		$$ref{'tooltip'} = [] if (!exists($$ref{'tooltip'}));
		push(@{$$ref{'tooltip'}}, bless { 'id'=>$links{$refn}{'id'}, 'n' =>$links{$refn}{'n'} },'LINK');
	    }
	}

    } elsif ($l =~ $RE_func_decl) {
	#403(@8) == func^ [func2]
	#{{+:func2:[
	my ($id,$declid,$exp,$funcn) = ($1,$2,$3,$4);
	#print("Found +$funcn $exp\n");
	print ("Expecting '{{+' after :".$b[$bidx]."\n".$b[$bidx+1]."\n") if (!($b[$bidx+1] =~ $RE_funcbody_start));
	my ($funcn2) = ($1);
	printf("Function name mismatch: $funcn2 != $funcn\n") if ($funcn2 ne $funcn);
	if ($exp eq "^") {
	    print ("Found $funcn on funcstack [".join(" ",@funcstack)."]\n") if ($OPT{'dbgexpi'});
	    $do_export_public{$funcn} = $declid;
	    $do_export_declid{$declid} = $funcn;
	    cleanse_export($funcn);
	} else {
	    $do_export_static{$funcn} = $declid;
	}
    } elsif ($l =~ $RE_funcbody_start) {
	#{{+:func1
        my ($fn) = ($1);
	#print("Found +$fn\n");
	push(@funcstack,$fn);
	
    } elsif ($l =~ $RE_funcbody_end) {
        my ($fn) = ($1);
	#print("Found -$fn\n");
	while (scalar(@funcstack)) {
	    my $_fn = pop(@funcstack);
	    if ($_fn ne $fn) {
		print("Expect $fn to pop from function stack, got $_fn\n") ;
	    } else {
		last;
	    }
	} 
    } elsif ($l =~ $RE_structref_line) {
        # inserted by c-decl.c and c-typcheck.c
        # a previously declared struct component is referenced (i.e. a.b = 1;). Specifies the type declaratoin position
        # 441 <=[  {ref}  (a)  type [int ] typdecl at: <built-in>:0
	my ($id,$reftyp,$refn,$typ, $typdfile,$typdline) = ($1,$2,$3,$4,$5,$6);
	my $ref = { 'refdfile' => $typdfile, 'refdline' => $typdline, 'n' => $refn,'typ' => $typ};
	registerref($ref); push(@refs,$ref);
        if (exists($id{$id})) {
            $l[$id{$id}]{'ref'} = $ref;
            print("$reftyp : $id <= \"$refn\" typ \"$typ\"\@$typdfile:$typdline\n") if ($OPT{'dbgref'});
        } elsif (exists($mid{$id})) {
	    my $mp = $mid{$id}[scalar(@{$mid{$id}})-1];
	    instantiate_ref($mp,$ref);
	}
    }

#374 <=[ strct 2 [@(2)struct a a ] decl started at: [test1.c:6]-[test1.c:9]
#376(@2) <=[{decl} [a1] type [int ] decl at: <built-in>:0
#380(@2) <=[{decl} [a2] type [@(1)struct b b ] decl at: test1.c:2
    
    elsif ($l =~ $RE_struct_line) {
	my ($id, $structid, $kind, $n, $typ, $start,$end) = ($1,$2,$3,$4,$5,$6,$7);
	print("$kind $n ($start-$end): $structid\n") if ($OPT{'dbgstruct'});
	$structsid{$structid} = "$kind $n";
	my $struct = { 'fields' => [], 'html' => {}, 'id' => $structid };
	$_structs{$structsid{$structid}} = $struct;
	$structs{$structid} = $struct;
	$start =~ /([^:]*):([0-9]+)/ or die ("Cant decode fileaddr $start");
	my ($startfile,$startline) = ($1,$2);
	$end =~ /([^:]*):([0-9]+)/ or die ("Cant decode fileaddr $end");
	my ($endfile,$endline) = ($1,$2);
	print("Warning, structure starts in $startfile and end if $endfile\n") if ($startfile ne $endfile);
	pushlinerec($startfile,$startline,$endline, $struct);
        #$linerec{$startfile} = [] if(!exists($linerec{$startfile}));
	#push(@{$linerec{$startfile}},[$startline,$endline, $struct]);
	$$struct{'f'} = $startfile;
	$$struct{'fl'} = $startline;
	my $ref = { 'refdfile' => $startfile, 'refdline' => $startline, 'typ' => '$kind $n' };
        registerref($ref); 
	$$struct{'ref'} = $ref;
    } elsif ($l =~ $RE_structdec_line) {
	my ($id,$structid,$n,$start, $typ, $f,$fl) = ($1,$2,$3,$4,$5,$6,$7);
        
        if (!($f =~ /<built\-in>/)) {
            
            my $ref = { 'refdfile' => $f, 'refdline' => $fl, 'n' => $n,'typ' => $typ};
            registerref($ref); push(@refs,$ref);
            
            if (exists($id{$id})) {
                $l[$id{$id}]{'ref'} = $ref;
                print("$reftyp : $id <= \"$n\" typ \"$typ\"\@$typdfile:$typdline\n") if ($OPT{'dbgref'});
            } elsif (exists($mid{$id})) {
                my $mp = $mid{$id}[scalar(@{$mid{$id}})-1];
                instantiate_ref($mp,$ref);
            }
        }
	my ($fieldfile, $fieldline) = ("",0);
	if ($start =~ m/([^:]*):([0-9]+)/) {
	    ($fieldfile, $fieldline) = ($1,$2); 
	}
	my $refstruct = -1;
	if ($typ =~ /^\@\(([0-9]+)\)\->\@\(([0-9]+)\)/ ||
	    $typ =~ /^\@\(([0-9]+)\)/) {
	    $refstruct = $1;
	}
	
 	push(@{$structs{$structid}{'fields'}},{ 'n' => $n, 'typ' => $typ, 'f' => $f, 'fl' => $fl, 'ffile' => $fieldfile, 'fln' => $fieldline, 'typid' => $refstruct });
    }
    
    #379 <=[ tdef (@1->d@3) [@(2)->@(1)_a :_b] decl [test.c:1]-[test.c:7]
    elsif ($l =~ $RE_tdef_line) {
        my ($id,$kind,$src,$dst,$type,$start,$end) = ($1,$2,$3,$4,$5,$6,$7);
        $structsid{$structid} = "$kind $n";
        $type =~ /:(.*)$/ or die("Cant find typedef specifier in $type");
        my $n = $1;
	my $typedef = { 'html' =>  {}, 'id' => $dst, '_n' => $n };
	$typedefs{$dst} = $typedef;
	$start =~ /([^:]*):([0-9]+)/ or die ("Cant decode fileaddr $start");
	my ($startfile,$startline) = ($1,$2);
	$end =~ /([^:]*):([0-9]+)/ or die ("Cant decode fileaddr $end");
	my ($endfile,$endline) = ($1,$2);
	print("Warning, typedef $n starts in $startfile and end if $endfile\n") if ($startfile ne $endfile);
        
	pushlinerec($startfile,$startline,$endline, $typedef);
	$$typedef{'f'} = $startfile;
	$$typedef{'fl'} = $startline;
	my $ref = { 'refdfile' => $startfile, 'refdline' => $startline, 'typ' => "$kind $n" };
        registerref($ref); 
	$$typedef{'ref'} = $ref;
        print("$kind $n ($start-$end): $type\n") if ($OPT{'dbgstruct'});
	
    }
    
    elsif ($l =~ $RE_decl_line) {
        # inserted by c-decl.c and c-typcheck.c
        # declare a variable (i.e. int a;); specify the type declaration position
        # 444 <=[ decl  [int  (/* ??? */):f1]] at [test.c:4]-[test.c:5] type(@10) [int  (/* ??? */)] decl at: <built-in>:0
        my ($id,$declid,$decl,$start,$end,$typid,$typ,$typedefid,$typdfile,$typdline) = ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10);
	
        #if (!($typdfile =~ /<built\-in>/))
	{
            $start =~ /([^:]*):([0-9]+)/ or die ("Cant decode fileaddr $start");
            my ($startfile,$startline) = ($1,$2);
            $end =~ /([^:]*):([0-9]+)/ or die ("Cant decode fileaddr $end");
            my ($endfile,$endline) = ($1,$2);
            my $declaration = { 'html' => {}, 'id' => $declid, 'decl' => $decl };
            $decls{$declid} = $declaration;
            
            pushlinerec($startfile,$startline, $endline, $declaration);
            #push(@{$linerec{$startfile}},[$startline, $endline, $declaration]);
            print ($declid.":".$decl." at $startfile:$startline\n") if ($OPT{'dbgdecl'});
            
            my $dec = { 'refdfile' => $startfile, 'refdline' => $startline, 'typ' => $typ, 'typid' => $typid, 'decl' => $decl};
            $$declaration{'ref'} = $dec;
            
            #$$dec{'tooltip'} = [] if (!exists($$dec{'tooltip'}));
            #push(@{$$dec{'tooltip'}}, bless { 'id'=>$typid },'STRUCT');
            
            registerref($dec); push(@refs,$dec);
            if (exists($id{$id})) {
                $l[$id{$id}]{'ref'} = $dec;
                print("Decl: $id <= \"$decl\" typ \"$typ\" \@$typdfile:$typdline\n") if ($OPT{'dbgdef'});
		if ($decl =~ /:([a-zA-Z_0-9]+)$/) {
		    my $refn = $1;
		    if (exists($links{$refn}) && $links{$refn}{'e'} eq 'e') {
			$$declaration{'extern'} = $links{$refn}{'id'};
		    } else {
			push(@do_export,[$refn,$declaration,$dec]);
		    }
		}
            } elsif (exists($mid{$id})) {
                my $mp = $mid{$id}[scalar(@{$mid{$id}})-1];
                instantiate_ref($mp,$ref);
            }
        }
        
    } elsif ($l =~ $RE_lmark_line) {
        # set the current line number
	# 2 test.c
        ($cline,$cfile) = ($1,$2);
        my ($ol,$of) = ($$fstack{'l'},$$fstack{'f'});
        $$fstack{'l'} = $cline;
        $$fstack{'f'} = $cfile;
        if ($cline > $ol) {
            push(@l,join("",("\n") x ($cline - $ol)));
        }
	fileline($cfile);
    } elsif ($l =~ $RE_direcinc_line) {
        # when a #include directive is reached. This is immediatly followed by a 
	# "2@#include + test.c" file open directive Used to retrive the real #include directive str.
	# #include "test.c"
	my ($fn) = $1.$2;
	#print ($fn."\n");
        $$fstack{'l'}+=2; # newline to #include line + newline to next line
	if ($b[$bidx+1] =~ $RE_imark_line && ($2 eq '+' || $2 eq '+-')) {
	    if ($2 eq '+-') {
		my ($line,$f) = ($1,$3);
                $bidx++;
                my $b = pushfileopenblock($f);
                $$b{'fl'} = $line-1;
                push(@{$$b{'skip'}},{ 'l' => 0, 'skip' => 1});
                push(@{$$b{'skip'}},{ 'l' => $$b{'u'}-1, 'skip' => $gctx{'skip'}});
                push(@l,$b);
                fileout("+-") ;
                $$b{'line'} = "$fn";
                my $f = pop(@fstack);
                push(@l,bless { 'fid' => $fstack[$#fstack]{'fid'}, 'srcfid' => $$f{'fid'}, 'typ' => 'fclose' },'BLOCK');
                
                
            } else {
		my ($line,$f) = ($1,$3);
                $bidx++;
                my $b = pushfileopenblock($f);
                $$b{'fl'} = $line;
                push(@l,$b);
                $$b{'line'} = "$fn";
                fileout("+") ;
            }
        } else {
            print ("Expecting '2@#include + file.c' after #include: ".$$fstack{'f'}."\@$bidx:".$b[$bidx]."\n".$b[$bidx+1]."\n"); 
        }
    } elsif ($l =~ $RE_imark_line) {
        # a previous "2@#include + test.c" directive is closed again
	# 2@include [+|-]
        if ($2 eq '-') {
	    die("Unopend include close\n") if (scalar(@fstack) <= 0);
	    my $f = pop(@fstack);
	    push(@l,bless { 'fid' => $fstack[$#fstack]{'fid'}, 'srcfid' => $$f{'fid'}, 'typ' => 'fclose' },'BLOCK');
            fileout("-") ;
	} else {
	    my $f = $3;
	    my $b = pushfileopenblock($f);
            push(@l,$b);
	}
    } elsif ($l =~ $RE_rename_line) {
        # switch from the buildin <buildin> and <command-line> filenames to
        # the main file.
        # # rename test.c
        if ($b[$bidx+1] =~ $RE_lmark_line) {
            $$fstack{'u'} = $$fstack{'l'}+1;
	    $bidx++;
            my $b = pushfilerenameblock($2,$1);
            push(@l,$b);
            fileline($2);
            fileout("=") ;
        } else {
            print ("Expecting '2@#include + file.c' after #include: ".$$fstack{'f'}."\@$bidx:".$b[$bidx]."\n".$b[$bidx+1]."\n"); 
        }
    } elsif ($l =~ $RE_dstate_line) {
        my ($lstart,$lend,$stateold,$state) = ($1,$2,$3,$4);
        if ($state) {
            # disable
            push(@{$$fstack{'skip'}},{ 'l' => $lend, 'skip' => $state});
        } else {
            # enable
            push(@{$$fstack{'skip'}},{ 'l' => $lstart, 'skip' => $state});
        }
        $gctx{'skip'} = $state;
    } elsif ($l =~ $RE_define_line) {
        my ($macroid,$n,$start,$end,$def) = ($1,$2,$3,$4,$5);
        $start =~ /([^:]*):([0-9]+)/ or die ("Cant decode fileaddr $start");
	my ($startfile,$startline) = ($1,$2);
	$end =~ /([^:]*):([0-9]+)/ or die ("Cant decode fileaddr $end");
	my ($endfile,$endline) = ($1,$2);
	
	my $dirid = $macroid;
        my $dir = { 'html' => {}, 'id' => $dirid, 'decl' => $decl ,'n' => $n,'_n' => $n, 'def' => $def};

        $dirs{$dirid} = $dir;
        
        pushlinerec($startfile,$startline, $endline, $dir);
        #push(@{$linerec{$startfile}},[$startline, $endline, $dir]);
        print ("macro $macroid $n: at $startfile:$startline\n") if ($OPT{'dbgdir'});
	
	my $ref = { 'refdfile' => $startfile, 'refdline' => $startline, 'n' => $n,
                    'tooltip'=> [(bless { 'id'=>$dirid },'MACRO')]};
	registerref($ref); push(@refs,$ref);
        $$dir{'ref'} = $ref;
        
        $dirid++;
    } elsif ($l =~ $RE_auxinfo_line) {
        my ($f,$line,$typ0,$typ1,$def) = ($1,$2,$3,$4,$5);
        if ($def =~ /[ \*]([a-zA-Z_0-9]+) \(/) {
	    my ($fn) = ($1);
	    print("Func $fn $typ0,$typ1: $f:$line\n") if ($OPT{'dbgaux'});
	    if ((!exists($auxinfo{$fn})) ||
		!($auxinfo{$fn}{'typ1'} eq 'F')) {
		$auxinfo{$fn} = {'f'=>$f,'fl'=>$line,'typ0'=>$typ0,'typ1'=>$typ1};
	    }
	}
    } elsif ($l =~ $RE_cdecl_line ) {
    } elsif ($l =~ $RE_paste_line) {
	# register a token paste operation in @pp. This array is used  to 
        # deduce a macro call that includes pasted tokens: "#define a(b,c) e(c##c)"
        my ($line,$id,$path,$l0,$l1,$r) = ($1,$2,$3,$4,$5,$6);
	push(@pp,[$path,$l0,$l1,$r]);
        $ppid{$r} = [$l0,$l1,$path];
	$id{$r} = -1; # do not undef. Needed by anchor
        #print($r."\n");
        #die("DFDF") if (exists($id{$r}));
    } elsif ($l =~ $RE_direc_line) {
    } else {
        # a line, advance file line 
        $l .= "\n"; # from previous split
        push(@l,$l);
	my $lin = $l;
	my $lcnt = ($lin =~ tr/\n/\n/);
        $$fstack{'l'} += $lcnt;
    } 
}

map { registerref($_); } @m_def_ref;

print dumpstruct(\%structs) if ($OPT{'dbgstruct'});
print Dumper(\%mid) if ($OPT{'dbgmid'});
print Dumper(\%mdom) if ($OPT{'dbgmdom'});
print Dumper(\%refs) if ($OPT{'dbgref'});

#print (Dumper(%ppid));

foreach  $ref (@refs) {
    if (exists($$ref{'typ'})) {
	my $typ = $$ref{'typ'};
        if ($typ =~ /^\@\(([0-9]+)\)\->\@\(([0-9]+)\)/) {
            $$ref{'tooltip'} = [] if (!exists($$ref{'tooltip'}));
	    push(@{$$ref{'tooltip'}}, ((bless { 'id'=>$1 },'TYPDEF'),(bless { 'id'=>$2 },'STRUCT')));
        } elsif ($typ =~ /^\@\(([0-9]+)\)/) {
            $$ref{'tooltip'} = [] if (!exists($$ref{'tooltip'}));
	    push(@{$$ref{'tooltip'}}, (bless { 'id'=>$1 },'STRUCT'));
	}
    }
}

foreach $fref (@frefs) {
    my ($n,$refdfile,$refdline) = @$fref{'n','refdfile','refdline'};
    if (!($do_export_public{$n} ||
	  $do_export_static{$n})) {
	$$fref{'ispublic'} = 1;
    }
    if (exists($auxinfo{$n})) {
	my $fd = $auxinfo{$n};
	my ($f,$fl,$typ0,$typ1) = @$fd{'f','fl','typ0','typ1'};
	if ($typ1 eq 'F' &&
	    ($refdfile ne $f ||
	     $refdline != $fl)) {
	    unregisterref($fref) or die("Could not unregister ".Dumper($fref));
	    $$fref{'refdfile'} = $f;
	    $$fref{'refdline'} = $fl;
	    registerref($fref);
	    print ("=ref> : $f defined at $f:$fl\n") if ($OPT{'dbgref'});
	}
    }
}

# reinitialize the %pid hash to beginiing of file
%pid = ();
# process macros
foreach my $mk (@ml) {
    my $mv = $ml{$mk}; my @a = (); my @b = (); my $m = { 'n' => $mk, 'id' => $mk};
    for (my $i = 0; $i < scalar(@$mv); $i++) {
	my $l = $$mv[$i];
	die ("Cant match macro line $l\n") if (!($l =~ $RE_macro_line ));
	# process a line:
	# <=393	(1)	#	NAME	[a](@103)#soft/include/t/t_tag1.c:5#a(v) 1+v
	my ($id,$path,$op,$typ,$tok) =  ($1,$2,$3,$4,$5);
	if ($i == 0) {
	    die ("Macro definition shoud start with tok type \"NAME\" in $l") if ($typ ne 'NAME');
	    die ("Id should point to tokenid anchor in macro def $l\n") if (!($id =~ /^<=([0-9]+)/));
	    my ($a) = ($1);
	    $$m{'a'} = $a;
	    die ("token should start with macro name in $l\n") if (!($tok =~ /^([a-zA-Z0-9_]+)\]\(\@([0-9]+)\)#(.*)$/));
	    my ($n,$mid,$d) = ($1,$2,$3);
	    @$m{'mid','n','desc'} = ($mid,$n,$d);
	    
	    if (exists($dirs{$mid})) {
		#die("$mid", $dirs{$mid}{'ref'}{'n'});
                $$m{'ref'} = $dirs{$mid}{'ref'};
            }
            print("$a anchor doesnt exist: $l\n") if ((!exists($id{$a})) && (!exists($pid{$a})));
	    my $last_choice = undef;
            # search for token id $a
	    #print("Anchor $a\n");
	    #if (!$id{$a}) {
	    {
		# not a toplevel token. Search inside macros. Use all
		# path definitions registered for token id $a
		#print("search $a\n");
	    
		my $r = $pid{$a};
		for(my $k = scalar(@$r)-1; $k >= 0; $k--) {
		    my $p0 = $$r[$k];
		    die ("Unknown format of path: $p0") if (!($p0 =~ /^[\[\(]([0-9\.]+)[\]\)]\.([0-9\.]+)/));
		    $_p0 = $1;
		    die ("Unknown format of path: $p0") if (!($path =~ /^[\[\(]([0-9\.]+)[\]\)]/));
		    $_p1 = $1;
		    print ("Searching for $a: Compare $_p0<=>$_p1 ($p0<=>$path)\n") if ($OPT{'dbgls'});
		    if (length($_p0) && length($_p1)) {
			
			my ($__p0,$__p1,$match) = ($p0,$_p1,0);
			if ($__p0 =~ /^[\(]([0-9\.]+)[\)]\.([0-9\.]+)/) {
			    # checking weather link to a macro argument: example (1).395:
#	<=393	(1)	#	NAME	[a](@103)#soft/include/t/t_tag1.c:5#a(v) 1+v
#	0	(1)	#	GRP	[(
#	395	(1)	v:	TOK	[n
#	396	(1)	v:	GRP	[(
#	397	(1)	v:	TOK	[2
#	398	(1)	v:	GRP	[)
#	0	(1)	#	GRP	[)
#	<=395	(2)	#	NAME	[n](@102)#soft/include/t/t_tag1.c:4#n(x) x+m
#	0	(2)	#	GRP	[(
#	397	(2)	x:	TOK	[2
#	0	(2)	#	GRP	[)
#	397	[2]		.x:	TOK	[2
			    my $__p0 = $1;
			    $__p0 =~ s/(?:[\.][0-9]+$)|(?:^[0-9]+$)//;
			    $__p1 =~ s/(?:[\.][0-9]+$)|(?:^[0-9]+$)//;
			    #print("Match $__p0 eq $__p1\n");
			    if ($__p0 eq $__p1) {
				print (" match\n") if ($OPT{'dbgls'});
				$match = 1;
			    }
			}
			if (substr($_p1,0,length($_p0)) eq $_p0) {
			    $match = 1;
			    print (" match substring\n") if ($OPT{'dbgls'});
			}
			# search here for a macro assignement in the toplevel that is preceding the current one.
			if ($_p0 =~ /^([0-9]+)$/ && $_p1 =~ /^([0-9]+)$/) {
			    my ($_p0_n,$_p1_n) = ($_p0, $_p1); 
			    if ((int($_p0_n) + 1) == int($_p1_n)) {
				$last_choice = $p0;
			    }
			}
			if ($match ) {
			    $$m{'r'} = $p0; #$$r[scalar(@$r)-1];
			    print("Linking $n($path) to macrotoken ".$$m{'r'}.", recursive\n") if ($OPT{dbgl});
			    die("Macro line ".$$m{'r'}." doesnt exist") if (!exists($mid{$$m{'r'}}));
			    $mid{$$m{'r'}}{'lnk'} = $mk;
			    splice(@$r,$k,1);
			    last;
			}
		    }
		}
	    }
	    if (!$match && $last_choice) {
	    ##define a c
            ##define c(v1) d(v1)
            ##define d(v) int v 
	    #a(a0);
#>#7@387:=>:TOK	[a
# #	<=387	(1)	#	NAME	[a](@102)#tmp/1_file1.c:1#a c
# #	365	[1]		|	TOK	[c
# #7@390::PAD	[
#>#7@365:=>:TOK	[c
# #7@0::GRP	[(
# #7@392:	v1:	TOK	[a0
# #7@0::GRP	[)
# #	<=365	(2)	#	NAME	[c](@103)#tmp/1_file1.c:3#c(v1) d(v1)
# #	0	(2)	#	GRP	[(
# #	392	(2)	v1:	TOK	[a0
# #	0	(2)	#	GRP	[)
# #	373	[2]		|	TOK	[d
# #	374	[2]		|	GRP	[(
# #	395	[2]		.v1:	PAD	[
# #	392	[2]		.v1:	TOK	[a0
# #	396	[2]		.v1:	PAD	[
# #	376	[2]		|	GRP	[)
# #1@398::PAD	[
	    # 
	    # The pinfo token stream for line 7 includes [a,c...]. The "out of order" part will take
            # care of this discrepancy because the source tokenizer's stream will be [a,...] only.
	    # The pinfo token streams' "c" member will be ignored. However then does a new problem
	    # occure: Actually the macro expansion should be registered to: recursive [1].365 not only  
	    # nonrecursive 365. Thererfore we do a heuristic that jumps over macro boundries

		print("Linking cross boundry $n($path) to macrotoken $last_choice, recursive\n") if ($OPT{dbgl});
		$$m{'r'} = $last_choice;
		$mid{$$m{'r'}}{'lnk'} = $mk;
		$mid{$$m{'r'}}{'lnk_jmp'} = { 'tokid' => $a };#collect_lnk_jmp($a);
	    }
	    if ($id{$a}) {
		print("Linking $n($path) to sourcetoken $a, non recursive\n") if ($OPT{dbgl});
                die("Line $a doesnt exist") if (!exists($id{$a}));
                $l[$id{$a}]{'lnk'} = $mk;
	    }
	} else {
	    die ("Path did not start with ( or [ in $l\n") if (!($path =~ /^[\(\[](.*)[\)\]]$/));
	    my $pid = $path.".".$id;
	    my $h; my $addnewline = 0;
	    if ($tok =~ s/\@\@\\\@\@//g)  {
		$addnewline = 1;
	    }
	    if ($path =~ /^[\(]/) {
                push(@a,{ 'typ' => 'CMT', 'tok' => "\@\@\\\@\@", 'op' => '|', 'id' => $path."0", 'pspc' => ' ' }) if ($addnewline);
		$h = { 'typ' => $typ, 'tok' => $tok, 'op' => $op, 'id' => $pid, 'pspc' => ' ' };
		if ($tok eq '.' || $tok eq '[' || (
                        $#a >= 0 && (
                            $a[$#a]{'tok'} eq '.' ||
                            $a[$#a]{'tok'} eq ']'))) {
                    $$h{'pspc'} = '';
                }
                push(@a,$h);
	    } else {
                push(@b,{ 'typ' => 'CMT', 'tok' => "\@\@\\\@\@", 'op' => '|', 'id' => $path."0", 'pspc' => ' ' }) if ($addnewline);
		$h = { 'typ' => $typ, 'tok' => $tok, 'op' => $op, 'id' => $pid, 'pspc' => ' ' };
		if ($tok eq '.' || $tok eq '[' || (
                        $#b >= 0 && (
                            $b[$#b]{'tok'} eq '.' ||
                            $b[$#b]{'tok'} eq ']'))) {
                    $$h{'pspc'} = '';
                }
                push(@b,$h);
	    }
	    #print("Search for $pid\n");
	    if (exists($refs{$pid})) {
		$$h{'ref'} = $refs{$pid};
	    }
            # a is is associated with a array of pids
	    $pid{$id} = [] if (!exists($pid{$id}));
	    push(@{$pid{$id}},$pid);
	    # $pid: [6.7].462
	    $mid{$pid} = $h;
	}
    }
    $$m{'a'} = [@a];
    $$m{'b'} = [@b];
    
    
    
    $m{$mk} = $m;

#     if ($$m{'id'} == "11897") {
# 	print ("Original##:\n".Dumper($m));
# 	$orim = $m;
#     }
}

propagate_line();

print Dumper($ml{$OPT{dbgma}}) if (exists($ml{$OPT{dbgma}}));
print Dumper(\%m) if ($OPT{dbgm});
dumperdbgpa() if ($OPT{dbgpa});


sub collectpp {
    my ($id,$i) = @_;
    my @r = ();
    if (exists($ppid{$id}) &&
        !exists($$i{$id})) {
        $$i{$id} = 1;
        my ($l0,$l1,$_p) = @{$ppid{$id}};
        return ($id,collectpp($l0),collectpp($l1));
    }
    return ($id);
}

sub searchpaste {
    my ($a,$c,$targetid) = @_;
    my $id0 = $$a[$c]{'id'};
    my $id1 = $$a[$c+1]{'id'};
    my $off = 0;
    die ("Targetid $targetid is invalid\n") if (!($targetid =~ /([0-9]+)$/));
    $targetid = $1;
    print("Search for target $targetid\n") if ($OPT{dbgpaste}); 
retry:    
    foreach my $pp (@pp) {
	my ($path,$l0,$l1,$r) = @{$pp};
	# must be '[<path>].id' square bracket version
	print("Search $id0,$id1 to paste:$path.[$l0,$l1]=>$r\n") if ($OPT{dbgpaste}); 
	if ($id0 eq $path.".".$l0 &&
	    $id1 eq $path.".".$l1) {
	    $off++;
	    if ($targetid eq $r) {
		return $off;
	    }
	    $id0 = $path.".".$r;
	    $id1 = $$a[$c+$off+1]{'id'};
	    goto retry;
	}
    }
    return 0;
}

sub formattok {
    my ($fstack,$tok,$newline) = @_;
    my $html = html_escape($$tok{'tok'});
    if (exists($$tok{'col'})) {
	$html = "<span class='".$$tok{'col'}."'>$html</span>";
    }
    $html =~ s/\@\@\\\@\@/<br>/g; # special \ newline 
    if(exists($$tok{'htm'})) {
        $html = $$tok{'htm'};
        $$newline = 0;
    }
    $html =~ s/\\n/\n/g; #comment newline unescape
    if (exists($$tok{'ref'})) {
	my $href = maprefid($fstack,$$tok{'ref'});
        $html = $href.$html."</a>";
    }
    return $html;
}

sub comparetokens {
    my ($a,$b) = @_;
    my $retry = 0;
    for(my $i = 0, my $j = 0; $i < scalar(@$a); $i++, $j++) {
        my $c = $$a[$i];
        my $d = $$b[$j];
        #print("Compare: ".$$c{'typ'}.$$d{'typ'}.$$c{'tok'},$$d{'tok'}."\n");
        if (cmpstr($$c{'typ'},$$d{'typ'}) &&
            cmpstr($$c{'tok'},$$d{'tok'})) {
            
        }  else {
            my $goon= 0;
            if($$c{'typ'} eq 'CMT' ||
               ($$c{'typ'} eq 'GRP' &&
                $$c{'tok'} eq ',')) {
                $j--;
            } elsif($$d{'typ'} eq 'CMT' ||
                    ($$d{'typ'} eq 'GRP' &&
                     $$d{'tok'} eq ',')) {
                $i--;
            } else {
                
                return 0;
            }
        }
    }
    #print("Found\n");
    return 1;
}

sub hidemultilineinvocation {
    my ($fstack,$id,$a) = @_;
    my ($cf, $cl, $ml) = @$fstack{'f','l','u'};
    my $ll = $cl-1;
    my $start = 0; my $depth = 0;
    my @tok = ();
    for(;$ll < $ml-1;$ll++) {
        my $p = $$fstack{'p'}[$ll];
        for (my $pi = 0; $pi < scalar(@$p);$pi++)  {
            if ($start == 0) {
		if ($$p[$pi]{'id'} == $id) {
		    # macro invocation can be out of line
		    # 1: macro
		    # 2: (arg1)
		    print("No macro invocation at line with id $id:".Dumper($$p[$pi+1])) if (((!($$p[$pi]{'tok'} eq 'defined')) &&
                                                                                              (!(($$p[$pi+1]{'typ'} eq 'GRP' &&
                                                                                                  $$p[$pi+1]{'tok'} eq '(') ||
												($$fstack{'p'}[$ll+1][0]{'typ'} eq 'GRP' &&
												 $$fstack{'p'}[$ll+1][0]{'tok'} eq '(')))) && !$OPT{'silent'});
		    #print("Start multiline \n");
		    
		    $start = 1;
		}
            } else {
                push(@tok,$$p[$pi]) if (exists($$p[$pi]{'typ'}));
                if ($$p[$pi]{'typ'} eq 'GRP' &&
                    $$p[$pi]{'tok'} eq '(') {
                    $depth++;
                } elsif ($$p[$pi]{'typ'} eq 'GRP' &&
                         $$p[$pi]{'tok'} eq ')') {
                    if (--$depth <= 0) {
			# print("found close:\n");
# 			foreach my $e (@tok) {
# 			    print Dumper($e);
# 			    print($$e{'tok'}.":".$$e{'typ'}."\n");
# 			}
# 			print("with\n");
# 			foreach my $e (@$a) {
# 			    print($$e{'tok'}.":".$$e{'typ'}."\n");
# 			}
			
			if (comparetokens($a,\@tok)) {
                            foreach my $tok(@tok) {
                                $$tok{'h'} = 1;
                            }
                            return 1;
                        }
                        return 0;
                    }
                }
            }
        }
        last if($start == 0);
    }
    return 0;
}


sub js_repfunc {
    my ($id,$fn,$str) = @_;
    $estr = js_escape_all($str);
    $f = "<script language=\"JavaScript1.3\" type=\"text/javascript\">top[document.htmltagid].repf_${id} = function (elem) { top[document.htmltagid].span.${fn}(elem,\"$estr\"); }</script>";
    if ($OPT{dbgjs}) {
	$f = "<!-- repf_${id}: $str --!>$f<!-- \n --!>";
    }
    return $f;
}
			
sub js_repfunc_lookup {
    my ($gctx,$ctx,$id,$fn,$mu,$me) = @_;
    if (exists($$gctx{'repfuncsdb'}{$mu}{$me})) {
	$id = $$gctx{'repfuncsdb'}{$mu}{$me};
    } else {
	$$gctx{'repfuncsdb'}{$mu}{$me} = $id;
	$re_mid = $id;
	$mu =~ s/þ([^þ]+)þ/$$1/eg;
	$me =~ s/þ([^þ]+)þ/$$1/eg;
	$$ctx{'repfuncs'} .= js_repfunc("${id}u",$fn,$mu);
	$$ctx{'repfuncs'} .= js_repfunc("${id}e",$fn,$me);
    }
    return $id;
}
			

sub converthtml {
    my ($a,$newline,$ctx,$allfstack,$fstack) = @_;
    my $html = ""; my $last = "";

p2: 
    # for all tokens in the line convert them to html token by token.
    # if the token has a macro expansion registerd to it then try to
    # match the arguments of the expansion and also include the exmansion
    # as javascripted expandable html. A macroexpansion is defined in the 
    # pinfo file as a "=>" "<=" pair:
    # ...
    #8@365:=>:TOK	[c
    # ...
    #	<=365	(2)	#	NAME	[c](@103)#tmp/1_file1.c:4#c(v1) d(v1)
    #...
    
   for (my $i = 0; $i < scalar(@$a); $i++) {
	my $l = $$a[$i];
        if ((exists($$l{'h'}))) {
            next;
        }
	
        if (ref($l) eq 'HASH')  {
            if ((exists($$l{'spc'}))) {
                $html .= html_escape($$l{'spc'});
	    }
            if ((exists($$l{'pspc'}))) {
                #if (!(!defined($fstack) && $last eq '.')) {
                    $html .= html_escape($$l{'pspc'});
                #}
	    }
            if ((exists($$l{'h'}))) {
		next;
	    }
	    if ((exists($$l{'lnk'}))) {
                
		my $lid = $gctx{'id'}++;
		local $gctx{'d'}; $gctx{'d'}++;
                my $dummy = 0;
                my $m = $m{$l->{'lnk'}};
		
                    
                #print ($re_mref);
                #print($mref);
                
                my ($n,$ma,$mb,$mid) = @$m{'n','a','b','mid'};
		
		#print "PROC :".DumpTokens($a);
		#print "a:".DumpTokens($a);
		#print $$m{'id'}.$$m{'n'}."{'ma'}:".DumpTokens($ma);
		#print $$m{'id'}.$$m{'n'}."{'mb'}:".DumpTokens($mb);
		
		#print $$m{'mid'}." PREMACRO:".DumpTokens($ma);
		#print Dumper($ma);

		my $mab = converthtml($ma,\$dummy,$ctx,$allfstack,undef);
		my $mbb = converthtml($mb,\$dummy,$ctx,$allfstack,undef);
                
                $re_mref = maprefid($fstack,$$m{'ref'});
		
                $re_toolclass = " class=\"def\" ";
                $re_mref =~ s/¶([^¶]+)¶/$$1/eg;
		
		if ($style_repspan) {
		    my ($m,$mu, $me) = ('','','');
		    if ($style_xml) {
			($m,$mu, $me) = ($repxmlspan_span,$repxmlspan_spanu,$repxmlspan_spane);
			$re_xmlfile_u = getxmlfilename($ostack,"T${lid}u"); #$outputxml;
			$re_xmlfile_e = getxmlfilename($ostack,"T${lid}e"); #$outputxml;
		    } elsif ($style_ajax) {
			($m,$mu, $me) = ($repajaxspan_span,$repajaxspan_spanu,$repajaxspan_spane);
                        $re_xmlfile_u = getxmlfilename($ostack,"T${lid}u"); #$outputxml;
			$re_xmlfile_e = getxmlfilename($ostack,"T${lid}e"); #$outputxml;
		    } else {
			($m,$mu, $me) = ($repspan_span,$repspan_spanu,$repspan_spane);
		    }

		    ($re_b,$re_id,$re_n,$re_def) = ($mab,$lid,$n,'#');
		    $mu =~ s/¶([^¶]+)¶/$$1/eg;
		    ($re_b,$re_id,$re_n,$re_def) = ($mbb,$lid,$n,'#');
		    $me =~ s/¶([^¶]+)¶/$$1/eg;
		    
		    
		    if ($style_xml) {

			($re_b,$re_id,$re_n,$re_def) = ($mu,$lid,$n,'#');
			$m =~ s/¶([^¶]+)¶/$$1/eg;
			
			# todo: check weather $mu($mab) and $me($mbb) are already saved, in that case compress
			$gctx{'xml'}{$re_xmlfile_u} .= "<T${lid}u>".xmlsplitlines($mu)."</T${lid}u>\n";
			$gctx{'xml'}{$re_xmlfile_e} .= "<T${lid}e>".xmlsplitlines($me)."</T${lid}e>\n";
		    } elsif ($style_ajax) {

			($re_b,$re_id,$re_n,$re_def) = ($mu,$lid,$n,'#');
			$m =~ s/¶([^¶]+)¶/$$1/eg;
			
			# todo: check weather $mu($mab) and $me($mbb) are already saved, in that case compress
			$gctx{'xml'}{$re_xmlfile_u} .= $mu;
			$gctx{'xml'}{$re_xmlfile_e} .= $me;
		    } else {
			# þre_idþ is not replace at this point, use it to compress
			    
			if ($nocompress == 0) {
			    
                            ($cid) = js_repfunc_lookup(\%gctx,$ctx,$lid,"replaceSpan",$mu,$me);
			    
                            $re_mid = $cid;
                            $mu =~ s/þ([^þ]+)þ/$$1/eg;
			    $re_mid = $cid;
			    $me =~ s/þ([^þ]+)þ/$$1/eg;
			    
			    ($re_b,$re_id,$re_n,$re_def) = ($mu,$lid,$n,'#');
			    $m =~ s/¶([^¶]+)¶/$$1/eg;
                        } else {

                            $re_mid = $lid;
                            $mu =~ s/þ([^þ]+)þ/$$1/eg;
                            $me =~ s/þ([^þ]+)þ/$$1/eg;
                            $m =~ s/þ([^þ]+)þ/$$1/eg;
                            
                            ($re_b,$re_id,$re_n,$re_def) = ($mu,$lid,$n,'#');
			    $m =~ s/¶([^¶]+)¶/$$1/eg;
			    
			    $$ctx{'repfuncs'} .= js_repfunc("${lid}u","replaceSpan",$mu); # set content to unexpanded state
			    $$ctx{'repfuncs'} .= js_repfunc("${lid}e","replaceSpan",$me); # set content to expanded state

		        }

			#$re_mid = $me_id;
			#$m =~ s/þ([^þ]+)þ/$$1/eg;

			#$$ctx{'repfuncs'} .= js_repfunc("_${lid}_u","replaceSpan",$mu); # set content to unexpanded state
			#$$ctx{'repfuncs'} .= js_repfunc("_${lid}_e","replaceSpan",$me); # set content to expanded state
		    }
		    
		    $html .= $m;
		    
		} else {
		    my ($mas, $mbs) = ($recspan_spanu,$recspan_spane);
		    ($re_b,$re_id,$re_n,$re_def) = ($mab,$lid,$n,'#');
		    $mas =~ s/¶([^¶]+)¶/$$1/eg;
		    ($re_b,$re_id,$re_n,$re_def) = ($mbb,$lid,$n,'#');
		    $mbs =~ s/¶([^¶]+)¶/$$1/eg;
		    $html .= $mas.$mbs;
		    $gctx{'onload'} .= "top[document.htmltagid].togglevisible('${lid}e');";
		}
		
		my $mabsz = scalar(@$ma); my $paste = 0; 
pcmt:		for (my $j = 0; $j < $mabsz; $j++) {
		    my $k0 = $$ma[$j];
		    my $k1 = $$a[$i+1+$j+$paste];
		    
                    #if ($$k1{'typ'} eq 'GRP' &&
                    #    $$k1{'tok'} eq '(') {
                    #    $brackdepth++;
                    #} elsif ($$k1{'typ'} eq 'GRP' &&
                    #    $$k1{'tok'} eq ')') {
                    #    $brackdepth++;
                    #}
                    
		    if (ref($k0) ne 'HASH' || ref($k1) ne 'HASH' ||
			(!cmpstr($$k0{'typ'},$$k1{'typ'})) ||
			(!cmpstr($$k0{'tok'},$$k1{'tok'}))
			) {
                        
                        if ($$k1{'typ'} eq 'CMT') {
                            $paste++; $j--; next pcmt;
                        }
		    
                        
			my $cp = $i+1+$j;
                        
                        # first try weather it is a multiline macro invocation:
                        if (defined($fstack)) {
                            die("Should have id set".Dumper($l)) if (!exists($$l{'id'}));
                            last p2 if (hidemultilineinvocation($fstack,$$l{'id'},$ma));
                        }
                        
                        # paste operation recovery. Trace the past log and deduce target token, wors only inside 
                        # macro definitions
			if (scalar(@$a) > ($cb+1)) {
			    my $c = searchpaste($a,$cp,$$k0{'id'});
			    if ($c) {
				$paste += $c;
				next;
			    }
			    die("Could not recover with #define a(b) c(b ## 1) paste check") if ($OPT{pastecheck});
			}
			# paste operration recovery failed. Search for bracket close
			my $j1 = $j;
			for ($j++;($j-$j1) < 1000 ;$j++) {
			    my $k1 = $$a[$i+1+$j];
			    if ($k1->{'typ'} eq 'GRP' &&
				$k1->{'tok'},")") {
				my $oldi = $i;
				$i = $i+1+$j;
				my $lnk_jmp_ok = 0; my @lnk = ();
				if (exists($$l{'lnk_jmp'})) {
				    my $tokid = $$l{'lnk_jmp'}{'tokid'};
				    my $line = $m->{'line'}; 
				    
				    #sub collect_lnk_jmp {
					#my ($id,$line,$size) = @_;
					#my @a = (); my %i;
					#map { $i{$_} = 1 } grep { $l[$_]{'line'} == $line } ($id{$id}, exists($idm{$id}) ? @{$idm{$id}} : ());
					#my @i = keys %i;
					#
					#print("Cannot extract lnk_jmp tokens tokenid:$id linenr:$line\n") if (scalar(@i) != 1);
					#my $i = $i[0];
					#my $cp = $l[$i]{'cp'};
					#my @l = @{$$fstack{'p'}[$line-1]};
					#my @p = @l[$cp..(scalar(@l))];
					#return @p;
				    #}
				    
				    #@lnk = collect_lnk_jmp($tokid,$line,scalar(@$ma));
				    
				    $lnk_jmp_ok = 1; #$OPT{'dbgnolnk'};
				}
				
				if (!$lnk_jmp_ok) {
				    #print "PROC :".DumpTokens($a);
				    
				    print "line to match:\n\n".DumpTokens($a);
				    print "link_jmp: ".DumpTokens(\@lnk)."\n" if (scalar(@lnk));
				    print "\n>Came till idx $j1. Macro to apply was:\n";
				    print $$m{'id'}."{'ma'}:".DumpTokens($ma);
				    print $$m{'id'}."{'mb'}:".DumpTokens($mb);
				
				    print ("Possible comment in multiline macro expansion or possible paste token a $oldi in argument list #define a(b) c(b ## 1) (todo). Token ".$$l{'id'}."\n") if (!$OPT{'silent'});
				}
				goto bailout;
			    }
			}
			die("Mismatch in tokens $j \n".Dumper($k0).Dumper($k1));
		    }
		}
		$i += ($mabsz + $paste);
bailout:		
                $last = "";
	    } else {
                $last = formattok($fstack,$l,$newline);
                $html .= $last;
	    }
	} 
    }
    return $html;
}

sub DumpTokens {
    my ($a) = @_;
    my @c0 = (); my $i = 0;
    foreach my $c (@$a) {
	push(@c0,"$i:[".$c->{'typ'}.":".comquote($c->{'tok'},10)."]"); $i++;
    }
    return _alignarray([[@c0]]);
}
sub tokenizeline {
    my ($fstack,$ll) = @_;
    my $l = $$fstack{'b'}[$ll];
    my $p = $$fstack{'p'}[$ll];
    my $o = $$fstack{'mo'}[$ll];
    my @tok = tokenize($$l[0],$o,\$$fstack{'m'},$fstack);
    if (scalar(@tok) == 0) {
        return ();
    }
    if ($OPT{'dbgprocess'}) {
        my @c0 = (); my $i = 0;
        foreach my $c (@tok) {
            push(@c0,"$i:[       :".$c->{'typ'}."):".comquote($c->{'tok'},10)."]"); $i++;
        }
        my @c1 = (); my $i = 0;
        foreach my $c (@$p) {
	    my $l = exists($$c{'lnk'}) ? '^' : " ";
            push(@c1,"$i:[".sprintf("$l%06d",$c->{'id'}).":".$c->{'typ'}."):".comquote($c->{'tok'},10)."]"); $i++;
        }
        my @c = ([ sprintf("src%04d: ",$cl), @c0 ],[ sprintf("pin%04d: ",$cl), @c1 ]);
        print(_alignarray(\@c));
    }
    return @tok;
}

sub getinccolor {
    my ($d) = @_;
    $d = 255 - ($d * 8);
    $d = 80 if ($d < 80);
    $b = $d * (0xef/0xff);
    return sprintf("%02x%02x%02x",$b,$b,$d);
}

sub getlinenr {
    my ($fstack) = @_;
    my ($cf, $cl, $ml) = @$fstack{'f','l','u'};
    my $ln = $ml < 10 ? sprintf("%01d",$cl) : 
            $ml < 100 ? sprintf("%02d",$cl) : 
            $ml < 1000 ? sprintf("%03d",$cl) : 
            $ml < 10000 ? sprintf("%04d",$cl) : 
            $ml < 100000 ? sprintf("%05d",$cl) : 
            $ml < 1000000 ? sprintf("%06d",$cl) : sprintf("%07d",$cl);
    if (exists($$fstack{'skipln'}) &&
	exists($$fstack{'skipln'}[$cl])) {
	return ("",$cl);
    }
    return ($ln.": ",$cl);
}

sub ostate_close {
    return "</span>";
}

sub ostate_open {
    if ($gctx{'skip'}) {
        return "<span style=\"color:#aaaaaa;\">";
    } else {
        return "<span style=\"color:#000000;\">";
    }
}

sub process {
    
    my ($fstack) = @_;
    my ($cf, $cl, $ml) = @$fstack{'f','l','u'};
    my $ll = $cl-1;
    my $l = $$fstack{'b'}[$ll];
    my $p = $$fstack{'p'}[$ll];
    my $html = "";
    
    if (scalar(@{$$fstack{'skip'}})) {
        if ($$fstack{'skip'}[0]{'l'} <= $cl) {
            $html .= ostate_close();
            $gctx{'skip'} = $$fstack{'skip'}[0]{'skip'};
            my $dummy = shift(@{$$fstack{'skip'}});
            $html .= ostate_open();
        }
    }
    
    if ($cl > 0) {
        
        my ($ln,$_cl) = getlinenr($fstack);
	
        my $refid = $refid{$cf}{$cl};
        
        $html .= "<a name='$refid'></a>" if (exists($linerefs{$cf}{$cl}));
        $html .= $ln;
        my $newline = 1;

	# copy over token attributes from pinfo tokens to tokenizer tokens
        if (scalar(@$p)) {
            die("Line already processed   $cf\@$cl\n") if (scalar(@$l) > 1);

	    #print Dumper($p);
	    
            my @tok = tokenizeline($fstack,$ll);
            if (scalar(@tok) == 0) {
                goto noline;
            }
            if (scalar(@tok) && $tok[$#tok]{'typ'} eq 'CMT') {
                my $l = $tok[$#tok]{'tok'};
                my $lcnt = ($l =~ tr/\n/\n/);
                $$fstack{'l'} += $lcnt;
            }
            my $retry = 0;
            for(my $i = 0, my $j = 0; $i < scalar(@$p); $i++, $j++) {
                my $c = $$p[$i];
                my $d = $tok[$j];
                if ($$c{'typ'} eq $$d{'typ'} &&
                    $$c{'tok'} eq $$d{'tok'}) {
                    if (exists($$c{'lnk'})) {
                        $$d{'lnk'} = $$c{'lnk'};
                        $$d{'lnk_jmp'} = $$c{'lnk_jmp'};
                        $$d{'id'}  = $$c{'id'};
                    }
                    $$d{'ref'} = $$c{'ref'} if (exists($$c{'ref'}));
                    $$d{'htm'} = $$c{'htm'} if (exists($$c{'htm'}));
                    $$d{'h'}   = $$c{'h'}   if (exists($$c{'h'}));
                }  else {
                    my $goon= 0;
                    if($$c{'typ'} eq 'CMT' ||
                       ($$c{'typ'} eq 'GRP' &&
                        $$c{'tok'} eq ',')) {
                        $j--;
                    } elsif($$d{'typ'} eq 'CMT' ||
                            $$d{'typ'} eq 'BDI' ||
                            ($$d{'typ'} eq 'GRP' &&
                             $$d{'tok'} eq ',')) {
                        $i--;
                    } else {
                        $retry = 1;
                        last;
                    }
                }
            }
            if (!$retry) {
                print ("     => aligned\n") if ($OPT{'dbgprocess'});
            } else {
                # couldnt match the whole line. Do it token by token.
              p1: 
                for(my $i = 0; $i < scalar(@$p); $i++) {
                    for(my $j = 0; $j < scalar(@tok); $j++) {
                        my $c = $$p[$i];
                        my $d = $tok[$j];
                        if ($$c{'typ'} eq $$d{'typ'} &&
                            $$c{'tok'} eq $$d{'tok'}) {
                            if (exists($$c{'lnk'})) {
                                $$d{'lnk'} = $$c{'lnk'};
                                $$d{'lnk_jmp'} = $$c{'lnk_jmp'};
                                $$d{'id'}  = $$c{'id'};
                            }
                            $$d{'ref'} = $$c{'ref'} if (exists($$c{'ref'}));
                            $$d{'htm'} = $$c{'htm'} if (exists($$c{'htm'}));
                            $$d{'h'}   = $$c{'h'}   if (exists($$c{'h'}));
                            next p1;
                        } 
                    }
                }
                print ("     => out of order\n") if ($OPT{'dbgprocess'});
            }

	    my %ctx = ('repfuncs' => '');
            my $myhtml = converthtml(\@tok,\$newline,\%ctx,$fstack,$fstack);
	    $html .= $ctx{'repfuncs'};
	    $html .= $myhtml;
            
        } else {
          noline:
            my $fl = join("",grep { ref($_) eq ''} @$l);
            if ($OPT{'dbgprocess'}) {
                my $fl0 = $fl;
                $fl0 =~ s/\n/\\n/g;
                printf("s%04d: %s\n",$cl,$fl0) ;
            }
            $html .= html_escape(join("",grep { ref($_) eq ''} @$l));
        }
        if ($newline) {
            $html .= "\n";
        }
        #todo multiple line recorders for a line may be present:
        # example: typedef struct a { } b;
        # this will add "struct a" and "typedef" line recorders.
	if (exists($linerec{$cf})) {
	    if (scalar(@{$linerec{$cf}}) > 0) {
                my $i = 0;
                while($i < scalar(@{$linerec{$cf}})) {
                    my ($start,$end,$struct) = @{$linerec{$cf}[$i]};
                    if ($cl > $end) {
                        last;
                    }
                    if ($cl >= $start && $cl <= $end) {
		        $$struct{'html'}{$cl} .= $html;
		    } 
		    $i++;
                }
                my ($start,$end,$struct) = @{$linerec{$cf}[0]};
                while ($end <= $cl) {
		    shift(@{$linerec{$cf}});
		    last if (scalar(@{$linerec{$cf}}) == 0);
		    ($start,$end,$struct) = @{$linerec{$cf}[0]};
		}
	    }
	}
    }
    
    
    $$ostack{'html'} .= $html;
    $$fstack{'l'}++;
}

$rstack = $bstack;
if (scalar(@fstack) >= 2) {
    if (exists($fstack[$_fb]{'inc'}[0]{'url'})) { #($OPT{'style'} =~ /multipage/) && 
        print ("Set root page ".$fstack[$_fb]{'inc'}[0]{'f'}." to $output\n") if ($OPT{dbgf});
	$fstack[$_fb]{'inc'}[0]{'url'} = $output;
        $rstack = $fstack[$_fb]{'inc'}[0];
    }
}

idref(); #create global line map

if ($style_ajax) {
    if ($OPT{'ajaxfile'}) {
	print("Todo: export funcs\n");
    } else {
	my $ctbl = $dbh->prepare("delete from ${re_sajax_prefix}_func where htmltag_func_fid=? and htmltag_func_linkid=?");
	$ctbl->execute($htmltag_html_fid,$htmltag_html_linkid);
	my $ctbl = $dbh->prepare("insert into ${re_sajax_prefix}_func (
htmltag_func_id,
htmltag_func_name,
htmltag_func_fid,
htmltag_func_linkid,
htmltag_func_desc ) values (?,?,?,?,?)");
	foreach my $funcn (keys %do_export_static) {
	    $ctbl->execute(NULL,$funcn,$htmltag_html_fid,$htmltag_html_linkid,'');
	}
	foreach my $funcn (keys %do_export_public) {
	    $ctbl->execute(NULL,$funcn,$htmltag_html_fid,$htmltag_html_linkid,'');
	    my $id = $dbh->last_insert_id(undef, undef, "${re_sajax_prefix}_func", undef);
	    $do_export_public_id{$funcn} = $id;
	    #print ("Export id for $funcn: $id\n");
	}
    }
}

sub do_export {
    my ($f,$n,$decl,$ref) = @_;
    my $fn = map2url($f,0).$outputpost;
    my $fnaj = map2url($f,0).".php";
    my ($_refid,$refdfile,$refdline,$refdfid) = @$ref{'refid','refdfile','refdline','refdfid'};
    $_refid = 0 if (!defined($_refid));
    my $g = "open_${refdfid}_${_refid}";
    my $gaj = "fid=${refdfid}&aid=${_refid}";
    if ($do_export_public{$n}) {
	my $funcid = $do_export_public_id{$n};
	#print("Couldnt retrive export id for $funcn: $funcid \n") if (!$funcid);
	print ("+Export $n ".$do_export_public{$n}." \n") if ($OPT{'dbgexport'});
	if ($style_xml) {
	    $exportdb_content =~ s/<SYM_${n}\s+.*<\/SYM_${n}>\n*//g;
	    my $e = "<SYM_${n} f=\"$fn\"><line>".html_escape("Symbol $n defined in <a href=\"$fn?$g\" title=\"$g\">$fn</a>")."</line></SYM_${n}>";
	    $exportdb_content =~ s/^<links>/<links>\n$e/ or die("Cannnot insert export into \"$exportdb_content\"\n");;
	} elsif (!($style_xml || $style_ajax)) {
	    $re_url = $fn;
	    $re_name = $n;
	    $re_refid = $_refid;
	    $re_refdfid = $refdfid;
	    my $r = $reloadtemplate_body;
	    $r =~ s/¶([^¶]+)¶/$$1/eg;
	    print ("Export $n to ".$outdir.(reload_filename($n))."\n") if $OPT{'verbose'};
	    writefile($outdir.(reload_filename($n)),$r);
	} elsif ($style_ajax) {
	    my $html = "<span class=\"export\"><a href=\"#any_URL\" title=\"fbrowse.from('$n')\" onclick=\"top[document.htmltagid].fbrowse.from(this,'1','f')\">[&lt;]</a><a class=\"export\" href=\"--server--/$fnaj?$gaj\" title=\"$fnaj\">goto external declaration: $n in ".$$f{'f'}."</a><a href=\"#any_URL\" onclick=\"top[document.htmltagid].fbrowse.to(this,'$n','t')\" title=\"fbrowse,to('$n')\">[&gt;]</a></span>";
	    if ($OPT{'ajaxfile'}) {
		print("Todo: export exports\n");
		sub export_html_filename {
		    my ($n,$linkid) = @_;
		    my $fn = "$outputdb/export/$linkid/$n";
		    return $fn;
		}
		if ($OPT{'ajaxfilecompress'}) {
		    $html = compress_data($html);
		}
			    
		writefile(export_html_filename($n,$htmltag_html_linkid), $html);
		writefile(export_html_filename($n,$htmltag_html_linkid)."__eid", "$funcid");

	    } else {
		if (exists($links{$n})) {
		    $fn = basename($fn);
		    $fn =~ s/html$/php/;
		    $links{$n}{'html'} = "Symbol $n defined in <a href=\"$fnaj?$gaj\" title=\"$g\">$fn</a>";
		}
		$ctbl = $dbh->prepare("insert into ${re_sajax_prefix}_export (
htmltag_export_name,
htmltag_export_eid,
htmltag_export_url,
htmltag_export_fid,
htmltag_export_linkid,
htmltag_export_desc ) values (?,?,?,?,?,?)");
		#$ntbl = $dbh->prepare("delete from ${re_sajax_prefix}_export where htmltag_export_name=? and htmltag_export_fid=?");
		$ntbl = $dbh->prepare("delete from ${re_sajax_prefix}_export where htmltag_export_name=? ");
		#$ntbl->execute($n,$htmltag_html_fid);
		$ntbl->execute($n);
		$ctbl->execute($n,
			       $funcid,
			       $html,
			       $htmltag_html_fid,
			       $htmltag_html_linkid,
			       '');

		#print("Export : $n, $funcid,$html,$htmltag_html_fid,$htmltag_html_linkid,
			       
		
	    }
	}
    }
}

foreach my $e (@do_export) {
    my ($refn,$declaration,$ref) = @$e;
    do_export($rstack,$refn,$declaration,$ref);
}

%gctx = ('d'=>1,'id'=>10,'jid'=>1, 'onload'=>'', 'xml' => '', 'skip' => 0);
$ostack = $fstack = $bstack;
@fstack = ($fstack);
$$ostack{'open'} = 0;
for (my $i = 0; $i < scalar(@l); $i++) {
    my $l = $l[$i]; 
    my ($fname,$fline) = @$fstack{'f','l'};
    if (ref($l) eq 'HASH')  {
    } elsif (ref($l) eq 'BLOCK')  {
        my $fid = $$l{'fid'};
	$new_ostack = $ostack;
	$new_fstack = $fid{$fid};
	$new_ostack = $new_fstack if ($OPT{'style'} =~ /multipage/);

	#print($$l{'typ'}.":".$$l{'f'}."\n");
	
        if ($$l{'typ'} eq 'fopen') {
            print("Flush: ".sprintf("%04d - %04d\n",$$fstack{'l'},$$l{'fl'})) if ($OPT{'dbgprocess'});
            while($$fstack{'l'} < $$l{'fl'}) {
                process($fstack); 
            }
        }
        if (($$l{'typ'} eq 'fclose' ||
             $$l{'typ'} eq 'frename') 
            && (!($OPT{'style'} =~ /multipage/))) {
#            && $$ostack{'open'} == 1) {
            while($$fstack{'l'} < $$fstack{'u'}) {
                process($fstack); 
            }
            while (scalar(@{$$fstack{'skip'}})) {
                $gctx{'skip'} = $$fstack{'skip'}[0]{'skip'};
                my $dummy = shift(@{$$fstack{'skip'}});
            }
            
            my $div = $divb1;
            $div =~ s/¶id¶/$fid/g;
            $$ostack{'html'} .= $div;
            $$ostack{'open'} = 0;
        }
        $$ostack{'html'} .= ostate_close();#.":here:".$$l{'typ'};
        
 	
	if (($$l{'typ'} eq 'fopen')) { # $$l{'typ'} eq 'frename'
            $$ostack{'html'} .= "<a name=\"F${fid}\"></a>";
            ($re_id,$re_div,$re_line,$re_style,$re_href,$re_class) = ($fid,'','[+|-]','','','fince');
            my $ll = $$fstack{'l'};
	    my $d = $$l{'d'} || 0;
            
            $re_style = "background-color: #".getinccolor($d).";";
            if(!($OPT{'style'} =~ /multipage/)) {

		$re_style .= "position: absolute;visibility: hidden"; #make hidden default
		$re_div = $divop."\n".$divb0;
		$re_line = html_escape("[+|-]".$$l{'line'} || '[+|-]');
		
            } else {
                $re_line = html_escape($$l{'line'} || '[+|-]');
		if ($style_xml || $style_ajax) {
		    my ($ln,$cl) = getlinenr($fstack);
		    $$fstack{'skipln'}[$cl] = 1;
		    
                    my ($m,$mu,$me) = ("","","");
                    if ($style_xml) {
                        # todo: check weather $mu($mab) and $me($mbb) are already saved, in that case compress
                        ($m,$mu,$me) = ($repxmldiv_div,$repxmldiv_divu,$repxmldiv_dive);
                        $re_xmlfile_u = getxmlfilename($ostack,"D${re_id}u"); #$outputxml;
                        $re_xmlfile_e = getxmlfilename($ostack,"D${re_id}e"); #$outputxml;
		    } elsif($style_ajax) {
                        # todo: check weather $mu($mab) and $me($mbb) are already saved, in that case compress
                        ($m,$mu,$me) = ($repajaxdiv_div,$repajaxdiv_divu,$repajaxdiv_dive);
                        $re_xmlfile_u = getxmlfilename($ostack,"D${re_id}u"); #$outputxml;
                        $re_xmlfile_e = getxmlfilename($ostack,"D${re_id}e"); #$outputxml;
                    }

		    ($re_b,$re_n,$re_def,$re_ln) = ('',$re_line,'#',$ln);
		    $mu =~ s/¶([^¶]+)¶/$$1/eg;
                    ($re_b,$re_n,$re_def,$re_ln) = ("¶re_b¶",$re_line,'#',$ln);
		    $me =~ s/¶([^¶]+)¶/$$1/eg;
		    ($re_b,$re_n,$re_def) = ($mu,$re_line,'#');
		    $m =~ s/¶([^¶]+)¶/$$1/eg;
		    
		    $$new_fstack{'xml'} = "D${re_id}e";
		    $$new_fstack{'xmlfile'} = $re_xmlfile_e;
		    $$new_fstack{'xmldive'} = $me;

                    if ($style_xml) {
                        $gctx{'xml'}{$re_xmlfile_u} .= "<D${re_id}u>\n".xmlsplitlines($mu)."</D${re_id}u>\n";
		    } elsif ($style_ajax) {
		        $gctx{'xml'}{$re_xmlfile_u} .= $mu;
                    }

		    #$gctx{'xml'}{$re_xmlfile} .= "<D${lid}e>".js_escape($me)."</D${lid}e>\n";
                    
		    $re_div = $m;
		    $re_href = map2url($new_fstack,1).$outputpost;
		    
		} else {
		    $re_div = $mutiref."\n";
		    $re_href = map2url($new_fstack,1).$outputpost;
		}
            }
            $re_div =~ s/¶([^¶]+)¶/$$1/eg;
            if ($ll > 0 && 
                $$fstack{'b'}[$ll-1][0] =~ /^#\s*include/ &&
                $ll == $$l{'fl'}) {

		#print("Include\n");
		my $tok = undef;
		if ($$fstack{'b'}[$ll-1][0] =~ /^#\s*[a-zA-Z_]+\s+((?:<[^>]*>|"[^"]*"))/) {
		    $tok = { 'tok' => $&, #$$fstack{'b'}[$ll-1][0],
			     'typ' => 'DIR',
			     'htm' => $re_div };
		} elsif ($$fstack{'b'}[$ll-1][0] =~ /^#\s*include\s+/) {
		    $tok = { 'tok' => $&, #$$fstack{'b'}[$ll-1][0],
			     'typ' => 'DIR',
			     'htm' => $re_div };
		}
		$$fstack{'p'}[$ll-1] = [] if(!exists($$fstack{'p'}[$ll-1]));
		unshift(@{$$fstack{'p'}[$ll-1]},$tok) if $tok;
		
                #$OPT{'dbgprocess'} = 1;
		process($fstack);
		#$OPT{'dbgprocess'} = 0;
            } else {
                $$ostack{'html'} .= $re_div;
            }
        } elsif (($$l{'typ'} eq 'frename')) {
	    $$new_ostack{'html'} .= "<a name=\"F${fid}\"></a>";
	}
	
        
        if ($$l{'typ'} eq 'fopen') {
            push(@fstack,$new_fstack);
            $$new_fstack{'l'} = $$new_fstack{'_l'};
            print("Switch: ".$$fstack{'f'}." -> ".$$new_fstack{'f'}."\n") if ($OPT{'dbgprocess'});
        } elsif ($$l{'typ'} eq 'frename') {
            $fstack[$#fstack] = $new_fstack;
            $$new_fstack{'l'} = $$new_fstack{'_l'};
            print("Switch: ".$$fstack{'f'}."@".$$fstack{'l'}." -> ".$$new_fstack{'f'}."@".$$new_fstack{'l'}."\n") if ($OPT{'dbgprocess'});
        } else {
            die("Unknown block type".$$l{'typ'}."\n") if ($$l{'typ'} ne 'fclose');
            my $f = pop(@fstack);
	    die("Mismatch fstack on stack fstack-top:\n".$fid{$$l{'srcfid'}}{'fid'}."\n")
                if ($fstack != $fid{$$l{'srcfid'}});
            while($$fstack{'l'} < $$fstack{'u'}) {
                process($fstack); 
            }
        }
	if (($$l{'typ'} eq 'fopen')) {
	    $$new_fstack{'dynopen'} =  [create_jsopen($new_fstack)];
	    $$new_fstack{'dynclose'} =  [create_jsclose($new_fstack)];
	    print ("Open for ".$$new_fstack{'f'}.":\n".join("\n",@{$$new_fstack{'dynopen'}})."\n") if ($OPT{'dbgfopen'});
	}
	
        $fstack = $fstack[$#fstack];
        $ostack = $new_ostack;
        $$ostack{'html'} .= ostate_open();
        
    } else {
        my $lcnt = ($l =~ tr/\n/\n/);
    }
}

while(scalar(@fstack)) {
    $fstack = pop(@fstack);
    while($$fstack{'l'} < $$fstack{'u'}) {
        process($fstack);
    }
}

sub comquote {
    my ($l,$n) = @_;
    $l =~ s/\n/\\n/g;
    $l = substr($l,0,$n)."..." if (length($l) > $n);
    return $l;
}



#%ctx = ('d'=>1,'id'=>10, 'onload'=>'');
#$sawdiv = 0;
#$html = nextline().converthtml(\@l,\%ctx,"");

sub nextline    { return "¶l_".(++($fstack[$#fstack]{'l'}))."¶"; }
sub nextlinediv { my $d = ($sawdiv ? "" : "\n").nextline(); $sawdiv = 0; return $d; }




###########################
#
sub get_dep_htlm {
    my ($d) = @_;
    my @d = get_mdep_source($d);
    #print("Search for dep of ".$OPT{'dbgmdep'}.":".$m_dep_n{$OPT{'dbgmdep'}}.":\n");
    my @p = map { $$_{'pos'} } @d;
    my @l = ();
    foreach my $l (@p) {
	my ($fn,$fl,$ref) = ($$l[0],$$l[1],$$l[2]);
	#print join("\n",map { $$_[0].":".$$_[1] } @p);
	#print("Filename: $fn\n");
	if (my $f = fileblock_fromname($fn)) {
	    push(@l,[basename($fn),$fl,$ref,$$f{'moa'}[$fl-1]]);
	}
    }
    my ($fn_m,$fl_m) = (1,1);
    foreach my $l (@l) {
	my ($fn,$fl,$ref,$m) = @$l;
	$fn_m = $fn_m > length($fn) ? $fn_m : length($fn);
	$fl_m = $fl_m > length("$fl") ? $fl_m : length("$fl");
    }
    return join("<br>",map { my ($fn,$fl,$ref,$m) = @$_; 
			     my $a = gotolink(1, $ref, 'o');
			     $a.sprintf("%-${fn_m}s@%0${fl_m}d:",$fn,$fl)."</a>".$m } @l);
}

if (defined($OPT{'dbgmdep'})) {
    print(get_dep_htlm($OPT{'dbgmdep'}));
    exit(0);
}

map { 
    my $d = get_dep_htlm($dirs{$_}{'n'});
    if (length($d)) {
	$dirs{$_}{'html'}{10000} .= "<br>Dependencies for ".$dirs{$_}{'n'}.":<br>".get_dep_htlm($dirs{$_}{'n'}) 
    }
} keys %dirs;

###########################
# format 

sub xmlsplitlines {
    my ($str) = @_;
    my $idx = 0; my @me = (); my $pos = 0; my $len = length($str);
    while(($pos < $len) && ($idx = index($str,"\n",$pos)) != -1) {
	push(@me,substr($str,$pos,($idx+1)-$pos));
	$pos = ($idx+1);
    }
    push(@me,substr($str,$pos)) if ($pos < $len);
    my $me = join("",map { " <line>".js_escape($_)."</line>\n" } @me);
    return $me;
}
###########################
# output
%fileindexctx = ( 'onload' => "");
$re_idx = fileindex(1,$rstack,\%fileindexctx);

my @fid_idx = ();
my @re_pathinit = ();
foreach my $f (values %fid) {
    my ($fid,$dynopen,$dynclose,$pid,$u) = @$f{'fid','dynopen','dynclose','pid','u'};
    $pid = $pid || -1;
    $u = $u || -1;
    my @inc = @{$$f{'inc'}};
    my @p = map { $$_{'fid'} } reverse collectpids($f,$rstack);
    my @r = grep { $$rstack{'fid'} == $_ } @p;
    if (scalar(@r)) {
        my $c = $fileindexctx{'idx'}{$fid};
        my $link = $fileindexctx{'link'}{$fid};
        my $linkopen = $fileindexctx{'linkopen'}{$fid};
        my $name = $fileindexctx{'name'}{$fid};
        my $pre = $fileindexctx{'pre'}{$fid} || 0;
        my $post = $fileindexctx{'post'}{$fid} || 0;
        
        $c =~ s/'/\\'/g;
        $link =~ s/'/\\'/g;
        $name =~ s/'/\\'/g;
        push(@re_pathinit,"þre_staticpathdefþ.pathdef.paths[\"${fid}\"] = { /*".$$f{'f'}."*/\n\t".
             "o: new Array( ".join(",\n",map {"\"$_\""} ($dynopen ? @{$dynopen} : ()))."),\n\t".
             "c: new Array( ".join(",\n",map {"\"$_\""} ($dynclose ? @{$dynclose} : ()))."),\n\t".
             (($rstack != $f) ? "p: $pid,\n\t" : "").
             "idx: '$c',\n\t".
             "l: '$link',\n\t".
             "lo: '$linkopen',\n\t".
             "n: '$name',\n\t".
             "u: $u,\n\t".
             "pre: $pre,\n\t".
             "post: $post,\n\t".
             "id: '".join(".",@p)."',\n\t".
             "ch: new Array(".join(",", map { $$_{'fid'} } @inc).") };");
    }
}
$re_fids_filename = $output;
$re_fids_basedir = dirname($output);
$re_fids_idx = join(",",map { "'".$$_{'fid'}."'" } collectcids($rstack,{}));
$re_pathinit = join("\n",@re_pathinit);
$re_pathinit =~ s/¶([^¶]+)¶/$$1/eg;
$re_staticpathdef = "top[document.htmltagid].path";
$re_pathinit_all =
 "þre_staticpathdefþ.pathdef = {
    b:     \"\",
    fids:  new Array(¶re_fids_idx¶),
    paths: new Array(),
    basedir: \"¶re_fids_basedir¶\",
    fileid: ¶re_sajax_fid¶,
    filename: \"¶re_fids_filename¶\"
};
".$re_pathinit;


if ($style_frames) {
    $re_fidx = $re_idx;
    $re_fidx_onload = $fileindexctx{'onload'};
    $re_idx = "";
    
}
$re_idx = "$re_idx" if (length($re_idx));
#print(":".$re_idx);
$re_struct = "";

map  { my $f = gettoolxmlfilename("L".$links{$_}{'n'}); $gctx{'xml_idonly'}{$f} = 1; } 
grep { ($links{$_}{'e'} eq 'e') } 
sort { int($links{$a}{'n'}) <=> int($links{$b}{'n'}) } keys %links;
    


my @all = (
    (map { $links{$_}{'id'} = $links{$_}{'n'}; $links{$_}{'N'} = 'L'; $links{$_}{'n'} = "<a href=\"#\" onclick=\"gotoexternal(this)\" >goto external [<i>$_</i>]</a>"; $links{$_} } 
     grep { !($links{$_}{'e'} eq 'e') } 
     (sort { int($links{$a}{'n'}) <=> int($links{$b}{'n'}) } keys %links)),
    (map { $structs{$_}{'N'} = 'S'; $structs{$_}{'n'} = "type [<i>$_</i>]"; $structs{$_} } 
     (sort { int($structs{$a}{'id'}) <=> int($structs{$b}{'id'}) } ($OPT{'dbgoutnomacro'} ? () : keys %structs))),
    (map { $typedefs{$_}{'N'} = 'T'; $typedefs{$_}{'n'} = "typedef [<i>".$typedefs{$_}{'_n'}."</i>]"; $typedefs{$_} } 
     (sort { int($typedefs{$a}{'id'}) <=> int($typedefs{$b}{'id'}) } keys %typedefs)),
    (map { $decls{$_}{'N'} = 'D'; $decls{$_}{'n'} = ($decls{$_}{'extern'} ? "extern " : "")."symbol [<i>".$decls{$_}{'decl'}."</i>]"; $decls{$_} } 
     sort {int($a) <=> int($b) } ($OPT{'dbgoutnomacro'} ? () : keys %decls)),
    (map { $dirs{$_}{'N'} = 'M'; $dirs{$_}{'n'} = "macro [<i>".$dirs{$_}{'n'}."</i>]"; $dirs{$_} } 
     sort {int($a) <=> int($b) } ($OPT{'dbgoutnomacro'} ? () : keys %dirs))
    );

$refstructelem_id = 1;
foreach my $v (@all) {
    my ($html,$ref,$n,$N);
    ($html,$re_id,$ref,$n,$N) = @$v{'html','id','ref','n','N'};
    my $joinhtml = join("",map { $$html{$_} } sort { ($a <=> $b) } (keys (%$html)));
    if (exists($$v{'fields'})) {
	my ($file,$startline,$endline) = @{$$v{'frec'}};
	my @f = (); my %f = (); my $typeref = 0;
	foreach my $f (@{$$v{'fields'}}) {
	    my ($fieldfile, $fieldline) = @$f{'ffile','fln'};
	    if ($file eq $fieldfile && $startline <= $fieldline && $endline >= $fieldline) {
		$f{$fieldline} = $f;
		$typeref = 1 if (defined($$f{'typid'}) && $$f{'typid'} != -1);
	    }
	}
	if ($typeref) {
	    $joinhtml = ""; my $opened = 0;
	    foreach my $line (sort { ($a <=> $b) } (keys (%$html))) {
		if (defined($f{$line}) &&
		    defined($f{$line}{'typid'}) && $f{$line}{'typid'} != -1) {
		    my $f = $f{$line};
		    my $sid = $$f{'typid'};
		    $joinhtml .= "</span>" if ($opened); $opened = 1;
                    my $fn = gettoolxmlfilename('S'.$sid);
		    $joinhtml .= "<div style=\"position:absolute;left:-2em;display:inline\" id='E--xmlid--$refstructelem_id.$sid'><a href=\"javascript:top[document.htmltagid].ajax.inlineajaxtool('--xmlid--$refstructelem_id.$sid','$fn','S${sid}')\">[+]</a></div><span id='A--xmlid--$refstructelem_id.$sid' class=\"structpre\"></span><span class=\"structelement\" id=\"E--xmlid--$refstructelem_id.$sid\">".$$html{$line};
		    $refstructelem_id++;
		} else {
		    $joinhtml .= "</span>" if ($opened); $opened = 0;
		    $joinhtml .= "<div style=\"position:absolute;left:-2em;display:inline\" >[=]</div>".$$html{$line};
		}
	    }
	    $joinhtml .= "</span>" if ($opened); $opened = 0;
	}
    }
    $re_html = "";
    my ($_refid,$refdfile,$refdline,$refdfid) = @$ref{'refid','refdfile','refdline','refdfid'};
    my $id = $refid++;
    $refdfile = html_escape($refdfile);
    if (exists($$v{'ref'})) {
	$re_html .= gotolink($id,$ref,"tooltip").$n." declared at [<i>$refdfile:$refdline</i>]</a>";
    } else {
	$re_html .= $n;
    }
    #$re_html .= $$v{'n'}; #public ";
    if ($$ref{'ispublic'}) {
    }
    $re_html .= "<pre class=\"tooltip\"><span style=\"color:#000000;\">".$joinhtml."<span></pre>";
    if ($style_xml) {
	my $f = gettoolxmlfilename("${N}$re_id");
	$gctx{'xml'}{$f} .= "<${N}${re_id}>".xmlsplitlines($re_html)."</${N}${re_id}>\n";
    } elsif ($style_ajax) {
	my $f = gettoolxmlfilename("${N}$re_id");
	$gctx{'xml'}{$f} .= $re_html;
    } else {
	my ($o,$c) = ($struct_divo,$struct_divc);
	$re_id = $N.$re_id;
	$o =~ s/¶([^¶]+)¶/$$1/eg;
	$c =~ s/¶([^¶]+)¶/$$1/eg;
	$re_struct .= $o."<span style=\"color:#000000;\">".$re_html."<span>".$c ;
    }
}
$re_struct = "$re_struct" if (length($re_struct));

if ($style_xml || $style_ajax) {
    foreach my $f (values %fid) {
        my ($fn) = @$f{'f'};
        if (length($$f{'html'})) {
            if (exists($$f{'xml'}) &&
                exists($$f{'xmlfile'}) &&
                exists($$f{'xmldive'})) {
                my $id = $$f{'xml'};
                
                my ($me) = ($$f{'xmldive'});
                $re_b = $$f{'html'};
                $re_b =~ s/--xmlid--//g;
                $me =~ s/¶([^¶]+)¶/$$1/eg;
                
                if ($style_xml) {
                    $me = xmlsplitlines($me);
                    $gctx{'xml'}{$$f{'xmlfile'}} .= "<${id}>\n".$me."</${id}>\n";
                } else {
                    $gctx{'xml'}{$$f{'xmlfile'}} .= $me;
                }

                #@me = split("\n",js_escape($me));
                #$me = join("",map { " <line>$_</line>\n" } @me);
                #print "$id:".$$f{'xmlfile'}.":".$me;
                
                #$gctx{'xml'}{$$f{'xmlfile'}} .= "<${id}>\n".$me."</${id}>\n";
            } 
        }
    }
    
    my %xml = ();
    foreach my $fn ((keys %{$gctx{'xml'}}), (keys %{$gctx{'xml_idonly'}})) {
        my ($fid,$id,$e);
        if ($fn =~ /ære__fid_([0-9]+)(?:_([LMDST]?[0-9ue]+))æ?/) {
            ($fid,$id,$e) = ($1,$2,$3);
        } elsif ($fn =~ /ære__fid_([0-9]+)(?:_(L[a-zA-Z_0-9]*))æ?/) {
            ($fid,$id,$e) = ($1,$2,$3);
        } else {
            die("$fn not right format ($fn), should be æfid[.id]æ");
        }
        if (length($id)) {
            $xml{$fid}{$id.$e}{'b'} .= $gctx{'xml'}{$fn};
            $xml{$fid}{$id.$e}{'nocontent'} = exists($gctx{'xml_idonly'}{$fn});
        } 
    }
    if ($style_ajax) {
        my %m = ();
        foreach my $fid (sort { $a <=> $b } keys %xml) {
            my $_fid = $xml{$fid};
            foreach my $id (sort { $a <=> $b } keys %{$_fid}) {
                my $_id = $$_fid{$id};
                if (${id} =~ /^L/) {
                    ${"re__fid_${fid}_${id}"} = -$htmltag_html_linkid;
                } else {
                    ${"re__fid_${fid}_${id}"} = $htmltag_html_fid;
                }
                if (!$$_id{'nocontent'}) {
                    $m{${id}} = $$_id{'b'};
                }
            }
        }
	if ($OPT{'ajaxfile'}) {
	    my $cmd = "rm -rf $outputdb/html/$linkid/$fid";
	    `$cmd`;
	} else {
	    $ntbl = $dbh->prepare("delete from ${re_sajax_prefix}_html where htmltag_html_fid=? and htmltag_html_linkid=?");
	    $ntbl->execute($htmltag_html_fid,$htmltag_html_linkid);
	}
        $ctbl = $dbh->prepare("insert into ${re_sajax_prefix}_html ( htmltag_html_name, htmltag_html_text, htmltag_html_fid, htmltag_html_linkid ) values (?,?,?,?)") if (!$OPT{'ajaxfile'});
        foreach my $k (sort keys %m) { #{$gctx{'xml'}}        
            my $m = $m{$k};
            $m =~ s/æ([^æ]+)æ/$$1/eg;
            $m =~ s/¶([^¶]+)¶/$$1/eg;
            $htmltag_html_name = $k;
            $htmltag_html_text = $m;
	    if ($OPT{'ajaxfile'}) {
		sub html_filename {
		    my ($n,$fid,$linkid) = @_;
		    my $fn = "$outputdb/html/$linkid/$fid/$n";
		    return $fn;
		}

sub compress_data {
    my ($input) = @_;
    eval ("use Compress::Raw::Bzip2 ;");
    #
    my $output = "";
    my ($bz, $status) = new Compress::Raw::Bzip2 [OPTS]
      or die "Cannot create bzip2 object: $bzerno\n";
    
    $status = $bz->bzdeflate($input, $output);
    $status = $bz->bzflush($output);
    $status = $bz->bzclose($output);
    return $output;
}
                if ($OPT{'ajaxfilecompress'}) {
		    $htmltag_html_text = compress_data($htmltag_html_text);
		}
		writefile(html_filename($htmltag_html_name,$htmltag_html_fid,$htmltag_html_linkid), $htmltag_html_text);
	    } else {
		$ctbl->execute($htmltag_html_name,$htmltag_html_text,$htmltag_html_fid,$htmltag_html_linkid);
	    }
        }

    } elsif ($style_xml) {
        my %f = (); my %d = ();
        my $_fn = map2url($bstack,0);
        my ($fb,$fi,$_fi,$di,$_di,$ds) = ($_fn.".","",0,"",0,0);
        
        if ($style_xmlmultifile) {
            $fi = "0";
        }
        if ($style_xmldir) {
            $di = $_fn."/".$ds."/";
            $fb = "";
        }
        foreach my $fid (sort { $a <=> $b } keys %xml) {
            my $_fid = $xml{$fid};
            foreach my $id (sort { $a <=> $b } keys %{$_fid}) {
                my $_id = $$_fid{$id};
                my $f = $di.$fb.$fi;
                ${"re__fid_${fid}_${id}"} = rel2outdir(filename($f.".xml"));
                #print "set re__fid_${fid}_${id}\n";
                $f{$f} .= $$_id{'b'};
                if ($style_xmlmultifile &&
                    $style_xmlfilesize < length($f{$f})) {
                    $_fi++;
                    $fi = $_fi;
                }
                if ($style_xmldir && 
                    $style_xmldirsize < ++$ds) {
                    $ds = 0;
                    $di = $_fn."/".($_di++)."/";
                }
            }
        }
        foreach my $fn (sort keys %f) { #{$gctx{'xml'}}        
            my $m = $f{$fn};
            $fn .= ".xml";
            $m =~ s/æ([^æ]+)æ/$$1/eg;
            $m =~ s/¶([^¶]+)¶/$$1/eg;
            print ("Writing xml output file $outdir$fn (".filename($fn).")\n") if ($OPT{verbose} && !$OPT{'quite'});
            writefile($outdir.filename($fn),"<file>\n".$m."</file>\n");
        }
    }
    
    #foreach my $fn (keys %{$gctx{'xml'}}) {
	#print ("Writing xml output file $fn\n");
	#writefile($fn,"<file>\n".$gctx{'xml'}{$fn}."</file>\n");
    #}
}

foreach my $f (values %fid) {

    my ($fn) = @$f{'f'};
    if (length($$f{'html'})) {
	if (exists($$f{'xml'}) &&
	    exists($$f{'xmlfile'}) &&
	    exists($$f{'xmldive'})) {
	    # my $id = $$f{'xml'};
	    
# 	    my ($me) = ($$f{'xmldive'});
# 	    $re_b = $$f{'html'};
#             $re_b =~ s/--xmlid--//g;
# 	    $me =~ s/¶([^¶]+)¶/$$1/eg;
# 	    $me = xmlsplitlines($me);
	    
# 	    #@me = split("\n",js_escape($me));
# 	    #$me = join("",map { " <line>$_</line>\n" } @me);
# 	    print "$id:".$$f{'xmlfile'}.":".$me;
	    
#	    $gctx{'xml'}{$$f{'xmlfile'}} .= "<${id}>\n".$me."</${id}>\n";
	} else {
	    if ($$f{'f'} ne '<base>' && !$$f{'renamed'}) {
		$o = map2url($f,0).$outputpost;

		my $jsn = $outdir.filename($o);
		$jsn =~ s/(?:.php$|.html$)// or die("$jsn doesnt end with .html|.php");
		$re_jsfile = dir2url($jsn);
		if (!$onserver) {
		    $re_jsfile = rel2outdir($re_jsfile);
		}                
		my $html = join("",map { $$_{'html'} } collectprepends($f));
                $html =~ s/--xmlid--//g;
		($re_body,$re_onload) = ($html,$gctx{'onload'});
		my $m = readfile($template);
                my $msajax = "";
                
                if ($style_ajax) {
                    $msajax = readfile($templatesajax);

		    while(1) {
			my $subcnt = 0;
			$subcnt += ($msajax =~ s/¶([^¶]+)¶/$$1/eg);
			$subcnt += ($msajax =~ s/þ([^þ]+)þ/$$1/eg);
			$subcnt += ($msajax =~ s/æ([^æ]+)æ/$$1/eg);
			last if (!$subcnt);
		    }
                }
                $re_sajax_mainfileid  = filename($o);
		if ($style_ajax) {
		    $re_fids_filename = $re_sajax_mainfileid;
		}
		
                #print($template.$m);
		my $b = dirname($outdir.filename($o));
                my $n = basename($outdir.filename($o));
                if ($style_ajax ) {
                    $o =~ s/html$/php/;
		    if (!($OPT{'unifiedtemplatebase'})) {
			writefile("$b/cfwSajax.php",$re_sajax);
			writefile("$b/cfwSajaxConfig.php",$re_sajax_config);
			writefile("$b/cfwConfig.php",$re_cfw_config);
		    }
                }

		if (($style_simple && !$style_multi ) || $rstack == $f) {

		    print ("Writing output file $outdir$o (".filename($o).")\n");
		    #print("Error"); exit(1);

                    $re_jsfile_idx = $re_jsfile;
		    $re_jsfilep = $re_jsfile.".";
		    if ($OPT{'unifiedtemplatebase'}) {
			$re_jsfilep = dir2url($OPT{'unifiedtemplatebase'});
			if (!$onserver) {
			    $re_jsfilep = rel2outdir($re_jsfilep);
			}                
			$re_jsfilep .= "/" if (!($re_jsfilep =~ /\/$/));
		    }
		    $re_jsfile_idxp = $re_jsfilep;

                    $re_unify_content = "";
                    $re_unify_content_main = "";
                    my @f = (".htmltag.js", ".htmltag.win.js",".htmltag.span.js",".htmltag.xml.js",".htmltag.path.js",".htmltag.pathdata.js",".htmltag.hash.js",".htmltag.css.js",".htmltag.tree.js",".htmltag.ptree.js",".htmltag.jquery.js",".htmltag.idx.js",".htmltag.fbrowse.js",".htmltag.ajax.js.php",".htmltag.css");
                    if ($OPT{'unifyjs'}) {
			if ($OPT{'unifiedtemplatebase'}) {
			    die("Cannot specify unifiedtemplatebase and unifyjs at the same time\n");
			}
                        foreach my $jsfn (".htmltag.jquery.js", ".htmltag.js", ".htmltag.win.js",".htmltag.span.js",".htmltag.xml.js",".htmltag.path.js",".htmltag.pathdata.js",".htmltag.hash.js",".htmltag.css.js",".htmltag.tree.js",".htmltag.ptree.js",".htmltag.idx.js",".htmltag.fbrowse.js") { # 
                            $re_unify_content .= "// ******************************************************************* \n";
                            $re_unify_content .= "// ******************** ${templatejs}${jsfn} ************************* \n";
                            $re_unify_content .= "// ******************************************************************* \n";
                            $re_unify_content .= readfile($templatejs.$jsfn)."\n";
			    @f = grep { $_ ne $jsfn } @f;
                        }
			#foreach my $jsfn (".htmltag.pathdata.js") {
                        #    $re_unify_content_main .= "// ******************************************************************* \n";
                        #    $re_unify_content_main .= "// ******************** ${templatejs}${jsfn} ************************* \n";
                        #    $re_unify_content_main .= "// ******************************************************************* \n";
                        #    $re_unify_content_main .= readfile($templatejs.$jsfn)."\n";
			#    @f = grep { $_ ne $jsfn } @f;
                        #}
                    } else {
			$m =~ s/<!--unifyjs-start//g;
			$m =~ s/unifyjs-end-->//g;
		    }
		    while($re_unify_content =~ s/¶([^¶]+)¶/$$1/eg) {};
		    while($re_unify_content =~ s/æ([^æ]+)æ/$$1/eg) {};
		    while($re_unify_content =~ s/þ([^þ]+)þ/$$1/eg) {};
                    while($re_unify_content_main =~ s/¶([^¶]+)¶/$$1/eg) {};
		    while($re_unify_content_main =~ s/æ([^æ]+)æ/$$1/eg) {};
		    while($re_unify_content_main =~ s/þ([^þ]+)þ/$$1/eg) {};
		    foreach my $jsfn (@f) {
		        #my $c = $content;
		        #if ((!$OPT{'unifyjs'}) || !($jsfn =~ /.htmltag.js$/)) {
                        $c = readfile($templatejs.$jsfn);
		        #}
			while(1) {
			    my $subcnt = 0;
			    $subcnt += ($c =~ s/¶([^¶]+)¶/$$1/eg);
			    $subcnt += ($c =~ s/þ([^þ]+)þ/$$1/eg);
			    $subcnt += ($c =~ s/æ([^æ]+)æ/$$1/eg);
			    last if (!$subcnt);
			}
			print ("Writing js output file $jsn$jsfn\n")  if ($OPT{veryverbose});
		        my $fn = $jsn.$jsfn;
			if ($OPT{'unifiedtemplatebase'}) {
			    $fn = $OPT{'unifiedtemplatebase'};
			    $fn .= "/" if (!($fn =~ /\/$/));
			    my $_jsfn = $jsfn;
			    $_jsfn =~ s/^\.//;
			    $fn .= $_jsfn;
			} 
			writefile($fn,$c);
		    }
		    if (-d $dtreeimages) {
		        my $d = dirname($jsn)."/".basename($dtreeimages);
		        if ($OPT{'unifiedtemplatebase'}) {
			    $d = $OPT{'unifiedtemplatebase'}."/".basename($dtreeimages);
			}
			mkpath([$d]);
		        `cp $dtreeimages/* $d;`;
		    }
		}
		while(1) {
		    my $subcnt = 0;
		    $subcnt += ($m =~ s/¶([^¶]+)¶/$$1/eg);
		    $subcnt += ($m =~ s/þ([^þ]+)þ/$$1/eg);
		    $subcnt += ($m =~ s/æ([^æ]+)æ/$$1/eg);
		    last if (!$subcnt);
		} 
                
		if (!($style_xml && ($rstack != $f))) {
		    print ("Writing b output file $outdir$o (".filename($o).")\n")  if ($OPT{verbose} && !$OPT{'quite'});
		    
                    if ($style_ajax) {
                        my $htmltag_html_name = $re_sajax_mainfileid;
                        my $htmltag_html_text = $msajax;
			if ($OPT{'ajaxfile'}) {
			    if ($OPT{'ajaxfilecompress'}) {
				$htmltag_html_text = compress_data($htmltag_html_text);
			    }
			    writefile(html_filename($htmltag_html_name,$htmltag_html_fid,$htmltag_html_linkid), $htmltag_html_text);
			} else {
			    my $ctblajax = $dbh->prepare("insert into ${re_sajax_prefix}_html ( htmltag_html_name, htmltag_html_text, htmltag_html_fid, htmltag_html_linkid ) values (?,?,?,?)");
			    $ctblajax->execute($htmltag_html_name,$htmltag_html_text,$htmltag_html_fid,$htmltag_html_linkid);
			    $ctblajax->finish();
			}
                    }
		    writefile($outdir.filename($o),$m);
                    if ($mediawiki) {
			deleteArticle(0,wikititle(filename($o)),$re_mediawiki_prefix);
			insertArticle(0,wikititle(filename($o)),$re_mediawiki_prefix,wikiwrap($m,$re_sajax_fid,$htmltag_html_linkid,$re_fids_filename));
		    } else {
			
		    }
		}
	    }
	}
    }
}

if ($mediawiki) {
    deleteArticle(0,"Naming_Conventions_${htmltag_html_linkid}_${htmltag_html_fid}",$re_mediawiki_prefix);
    insertArticle(0,"Naming_Conventions_${htmltag_html_linkid}_${htmltag_html_fid}",$re_mediawiki_prefix,"<cfw_tags file=\"l8/types/l8macro.h\" linkid=$htmltag_html_linkid fid=$htmltag_html_fid></cfw_tags>");
}

$re_staticpathdef = "\@";

while(1) {
    my $subcnt = 0;
    $subcnt += ($re_pathinit_all =~ s/¶([^¶]+)¶/$$1/eg);
    $subcnt += ($re_pathinit_all =~ s/þ([^þ]+)þ/$$1/eg);
    $subcnt += ($re_pathinit_all =~ s/æ([^æ]+)æ/$$1/eg);
    last if (!$subcnt);
}

if ($style_ajax && !$OPT{'ajaxfile'}) {
    
    my $ntbl = $dbh->prepare("delete from ${re_sajax_prefix}_file where htmltag_file_fid=? and htmltag_file_linkid=?");
    $ntbl->execute($htmltag_html_fid,$htmltag_html_linkid);
    $ntbl->finish();
    my $ctbl = $dbh->prepare("insert into ${re_sajax_prefix}_file ( htmltag_file_fid, htmltag_file_linkid, htmltag_file_path, htmltag_file_fn, htmltag_file_cfgid ) values (?,?,?,?,?)");
    $ctbl->execute($htmltag_html_fid,$htmltag_html_linkid,$re_pathinit_all,$re_fids_filename,0);
    $ctbl->finish();

    my $sel = $dbh->prepare("select htmltag_file_fid, htmltag_file_fn FROM ${re_sajax_prefix}_file WHERE htmltag_file_linkid=? ");
    $sel->execute($htmltag_html_linkid);
    my (@files,$fid,$fn);
    $sel->bind_columns( \$fid,\$fn );

    sub treecreate {
	my ($path,$n,$ctx,$def) = @_;
	if (scalar(@$path)) {
	    my $pn = shift(@$path);
	    $$ctx{'_d'}{$pn} = {'name' => $pn} if (!exists($$ctx{'_d'}{$pn}));
	    treecreate($path,$n,$$ctx{'_d'}{$pn},$def);
	} else {
	    $$ctx{'_n'}{$n} = $def;
	}
    }

    my %p = ('_ls' => 1, '_hs' => 1, _d=>{});
    while ( $sel->fetch() ) {
	push(@files,$fn);
	treecreate([split("/",dirname($fn))],basename($fn),\%p,{'fid'=>$fid,'name'=>basename($fn)});
    }
    $sel->finish();
    my $tree = "";
    
    $linktree_config_useLines = 1;
    $linktree_config_useIcons = 1;
    $linktree_config_useSelection = 0;
    $linktree_config_folderLinks = 0;
    $linktree_config_icon_root = 'img/base.gif';
    $linktree_config_icon_folder = 'img/folder.gif';
    $linktree_config_icon_folderOpen = 'img/folderopen.gif';
    $linktree_config_icon_node = 'img/page.gif';
    $linktree_config_icon_empty = 'img/empty.gif';
    $linktree_config_icon_line = 'img/line.gif';
    $linktree_config_icon_join = 'img/join.gif';
    $linktree_config_icon_joinBottom = 'img/joinbottom.gif';
    $linktree_config_icon_plus = 'img/plus.gif';
    $linktree_config_icon_plusBottom = 'img/plusbottom.gif';
    $linktree_config_icon_minus = 'img/minus.gif';
    $linktree_config_icon_minusBottom = 'img/minusbottom.gif';
    $linktree_config_icon_nlPlus = 'img/nolines_plus.gif';
    $linktree_config_icon_nlMinus = 'img/nolines_minus.gif';
    $linktree_config_nextid = 1;
    $linktree_obj = "tree.obj";
    $linktree_prefix_img = "\@/extensions/cfw/scripts/";
    
    preparetree(\%p);
    #print Dumper(\%p);
    my $linkstr = rendertree(\%p,[],0,{'level'=>0},1);
    if ($OPT{'dbglinktree'}) {
	writefile($OPT{'dbglinktree'},"<html><body>$linkstr</body></html>");
    }
    #print $linkstr;
    
    sub preparetree {
	my ($node) = @_;
	$$node{'_id'} = $linktree_config_nextid++;
	if (exists($$node{'_n'}) || exists($$node{'_d'})) {
	    my @pk = sort keys(%{$$node{'_d'}});
	    my @nk = sort keys(%{$$node{'_n'}});
	    $$node{'_da'} = [@pk]; 
	    $$node{'_na'} = [@nk]; 
	    for (my $i = 0; $i < scalar(@pk); $i++) {
		my $lc = (($i+1) == scalar(@pk)) && (scalar(@nk) == 0) ? 1 : 0;
		$$node{'_d'}{$pk[$i]}{'_ls'} = $lc;
		$$node{'_d'}{$pk[$i]}{'_hc'} = 1;
		$$node{'_d'}{$pk[$i]}{'_io'} = 1;
		preparetree($$node{'_d'}{$pk[$i]});
	    }
	    for (my $i = 0; $i < scalar(@nk); $i++) {
		my $lc = (($i+1) == (scalar(@nk))) ? 1 : 0;
		$$node{'_n'}{$nk[$i]}{'_ls'} = $lc;
		$$node{'_n'}{$nk[$i]}{'_hc'} = 0;
		$$node{'_n'}{$nk[$i]}{'_io'} = 1;
		preparetree($$node{'_n'}{$nk[$i]});
	    }
	}
    }
    sub renderindent {
	my ($node,$ar,$lc) = @_;
	my ($str,$subtreestr) = ("",""); my $m = 1;
	foreach my $i (@$ar) {
	    my $id = 'in'.$linktree_obj.$$node{'_id'}.'.'.$m ;
	    $src = "";
	    if ($i && $linktree_config_useLines) {
		$src = $linktree_config_icon_line;
	    } else {
		$src = $linktree_config_icon_empty;
	    }
	    $str .= '<img id="'.$id.'" src="'.$linktree_prefix_img.$src.'" alt="" />';
	    $id =~ s/\./_/g;
	    $subtreestr .= '<img class="'.$id.'" src="'.$linktree_prefix_img.$src.'" alt="" />';
	    $m++;
	}
	my $aid = 'a'.$linktree_obj.$$node{'_id'};
        my $id = 'j'.$linktree_obj.$$node{'_id'}; ;
        my $href = 'javascript:(function(){})();';
	$subtreestr =~ s/</&lt;/g;
	$subtreestr =~ s/>/&gt;/g;
	$subtreestr =~ s/"/&h;/g;
	if ($$node{'_hc'}) {
            my $href = 'javascript: ' . $linktree_obj . ".o('".$linktree_obj."'," . $$node{'_id'}.  ",'$subtreestr');";
            $str .= '<a id="'.$aid.'" href="'.$href.'"><img id="'.$id .'" src="';
	    my $src = "";
            if (!$linktree_config_useLines) { $src = $$node.{'_io'} ? $linktree_config_icon_nlMinus : $linktree_config_icon_nlPlus }
            else { $src = ( $$node{'_io'} ? (($$node{'_ls'} && $linktree_config_useLines) ? $linktree_config_icon_minusBottom : $linktree_config_icon_minus) :
			    (($$node{'_ls'} && $linktree_config_useLines) ? $linktree_config_icon_plusBottom : $linktree_config_icon_plus ) ); }
            $str .= $linktree_prefix_img.$src.'" alt="" /></a>';
        } else {
            my $src = ( ($linktree_config_useLines) ? (($$node{'_ls'}) ? $linktree_config_icon_joinBottom : $linktree_config_icon_join ) : $linktree_config_icon_empty);
            $str .= '<a id="'.$aid.'" href="'.$href.'"><img id="'.$id.'" src="'.$linktree_prefix_img.$src. '" alt="" />';
        }
	return ($str,$subtreestr);
    }
    
    sub rendertree {
	my ($node,$ar,$level,$ctx,$lc) = @_;
	my $prefix = join("",(" " x $level));
	my ($instr,$insubtree) = renderindent($node,$ar,$lc);
	my $str = "$prefix<div class=\"dTreeNode\" id=\"di".$linktree_obj.$$node{'_id'}."\">".$instr."\n";
	if ($linktree_config_useIcons) {
	    if (!$$node{'icon'}) {
		$$node{'icon'} = ($$node{'_hc'} ? $linktree_config_icon_folder : $linktree_config_icon_node);
	    }
	    if (!$$node{'iconOpen'}) {
		$$node{'iconOpen'} = ($$node{'_hc'} ? $linktree_config_icon_folderOpen : $linktree_config_icon_node);
	    }
	    $str .= '<img id="i'.$linktree_obj.$$node{'_id'}.'" src="' .$linktree_prefix_img.(($$node{'_io'}) ? $$node{'iconOpen'} : $$node{'icon'}) .'" alt="" />';
	}
	
	if ($$node{'url'}) {
	    $str .= '<a id="s' .$linktree_obj.$$node{'_id'}.'" class="' .(($linktree_config_useSelection) ? (($$node{'_is'} ? 'nodeSel' : 'node')) : 'node') . '" href="' .$$node{'url'}. '"';
	    if ($$node{'title'}) { $str .= ' title="' .$$node{'title'} . '"'; }
	    if ($$node{'target'}) { $str .= ' target="' . $$node{'target'} . '"'; }
	    $str .= '>';
	}
	elsif ((!$linktree_config_folderLinks || !$$node{'url'}) && $$node{'_hc'} ) {
	    $str .= '<a href="javascript: ' .$linktree_obj .'.o(' .$$node{'_id'}. ');" class="node">';
	}
	
	$str .= $prefix.$$node{'name'}."\n";
	if ($$node{'url'}) {
	    $str .= "</a>";
	}

	$str .= "$prefix</div>\n";
	
	
	if (exists($$node{'_n'}) || exists($$node{'_d'})) {
	    $str .= "$prefix<div id=\"d".${linktree_obj}.$$node{'_id'}."\" class=\"clip\" style=\"display:block;\">\n";
	    my @pk = @{$$node{'_da'}};
	    my @nk = @{$$node{'_na'}};
	    
	    for (my $i = 0; $i < scalar(@pk); $i++) {
		$str .= rendertree($$node{'_d'}{$pk[$i]},[@$ar,!$$node{'_ls'}],$level+1,$ctx,$lc);
	    }
	    for (my $i = 0; $i < scalar(@nk); $i++) {
		my $lc = (($i+1) == (scalar(@nk))) ? 0 : 1;
		$str .= rendertree($$node{'_n'}{$nk[$i]},[@$ar,!$$node{'_ls'}],$level+1,$ctx,$lc);
	    }
	    $str .= "$prefix</div>\n";
	} 
	return $str;
    }

#     $str = '<div class="dTreeNode" id="di'.this.obj.nodeId+'">' + renderindent(node, nodeId, false);
#     if (this.config.useIcons) {
#         if (!node.icon) node.icon = (0 && this.root.id == node.pid) ? this.icon.root : ((node._hc) ? this.icon.folder : this.icon.node);
#         if (!node.iconOpen) node.iconOpen = (node._hc) ? this.icon.folderOpen : this.icon.node;
#         if (0 && this.root.id == node.pid) {
#             node.icon = this.icon.root;
#             node.iconOpen = this.icon.root;
#         }
#         str += '<img id="i' + this.obj + nodeId + '" src="' + ((node._io) ? node.iconOpen : node.icon) + '" alt="" />';
#     }
#     if (node.url) {
#         str += '<a id="s' + this.obj + nodeId + '" class="' + ((this.config.useSelection) ? ((node._is ? 'nodeSel' : 'node')) : 'node') + '" href="' + node.url + '"';
#         if (node.title) str += ' title="' + node.title + '"';
#         if (node.target) str += ' target="' + node.target + '"';
#         if (this.config.useStatusText) str += ' onmouseover="window.status=\'' + node.name + '\';return true;" onmouseout="window.status=\'\';return true;" ';
#         if (this.config.useSelection && ((node._hc && this.config.folderLinks) || !node._hc))
#             str += ' onclick="javascript: ' + this.obj + '.s(' + nodeId + ');"';
#         str += '>';
#     }
#     else if ((!this.config.folderLinks || !node.url) && node._hc && node.pid != this.root.id)
#         str += '<a href="javascript: ' + this.obj + '.o(' + nodeId + ');" class="node">';
#     str += node.name;
#     if (node.url || ((!this.config.folderLinks || !node.url) && node._hc)) str += '</a>';
#     str += '</div>';

    
#     if (node._hc && dyn == -1) {
#         if (!node._hidden)
#             str += '<div id="d' + this.obj + nodeId + '" class="clip" style="display:' + ((this.root.id == node.pid || node._io) ? 'block' : 'none') + ';">';
#         str += this.addNode(node);
#         if (!node._hidden)
#             str += '</div>';
#     }
#     if (dyn == -1)
#         this.aIndent.pop();
#     return str;
# };

#     // Adds the empty and line icons
# top[document.htmltagid].tree.prototype.indent = function(node, nodeId, dyn) {
#     var str = '';
#     var subtreestr = '';
#     if (this.root.id != node.pid) {
#         for (var n=0; n<this.aIndent.length; n++) {
#             if (dyn) {
#             }
#             var id = 'in' + this.obj + nodeId + '.' + n ;
#             var src = ( (this.aIndent[n] == 1 && this.config.useLines) ? this.icon.line : this.icon.empty );
#             str += '<img id="' + id + '" src="' + src + '" alt="" />';
#             subtreestr += '<img class="' + id.replace(/\./g,'_') + '" src="' + src + '" alt="" />';
#             if (dyn) {
#                 $('#'+id.replace(/\./g,'\\.')).attr('src',src);
#                 $('#'+id.replace(/\./g,'\\.')).attr('alt','modiefied');
#                 $('.'+id.replace(/\./g,'_')).attr('src',src);
#                 $('.'+id.replace(/\./g,'_')).attr('alt','modiefied');
#             }
#         }
        
#         (node._ls) ? this.aIndent.push(0) : this.aIndent.push(1);
#         if (dyn) {
            
#         }
#         var aid = 'a' + this.obj + nodeId;
#         var id = 'j' + this.obj + nodeId;
#         var src = "";
#         var href = 'javascript:(function(){})();';
#         if (node._hc) {
#             href = 'javascript: ' + this.obj + '.o(' + nodeId + ');';
#             str += '<a id="'+aid+'" href="'+href+'"><img id="' + id + '" src="';
#             if (!this.config.useLines) src = (node._io) ? this.icon.nlMinus : this.icon.nlPlus;
#             else src = ( (node._io) ? ((node._ls && this.config.useLines) ? this.icon.minusBottom : this.icon.minus) : ((node._ls && this.config.useLines) ? this.icon.plusBottom : this.icon.plus ) );
#             str += src + '" alt="" /></a>';
#         } else {
#             src = ( (this.config.useLines) ? ((node._ls) ? this.icon.joinBottom : this.icon.join ) : this.icon.empty);
#             str += '<a id="'+aid+'" href="'+href+'"><img id="'+ id +'" src="' + src + '" alt="" />';
#         }
#         if (dyn) {
#             $('#'+id.replace(/\./g,'\\.')).attr('src',src);
#             $('#'+aid.replace(/\./g,'\\.')).attr('href',href);
#         }
        
#     }
#     node.subtreestr = subtreestr;
#     return str;
# };



    my @p = split("/",$path);
    
    my $cnt = $dbh->prepare("SELECT COUNT(*) FROM ${re_sajax_prefix}_link WHERE htmltag_link_linkid=?");
    my $row = $cnt->execute($htmltag_html_linkid);
    if (scalar($cnt->fetchrow_array())) {
	my $update = $dbh->prepare("update ${re_sajax_prefix}_link link SET  htmltag_link_tree = ?  where link.htmltag_link_linkid=?");
	$update->execute($linkstr,$htmltag_html_linkid);
    } else {
	my $insert = $dbh->prepare("insert into ${re_sajax_prefix}_link ( htmltag_link_linkid, htmltag_link_tree, htmltag_link_fn ) values (?,?,?)");
	$insert->execute($htmltag_html_linkid,$linkstr,'');
    }
}


if ($style_frames) {
    $_re_f_idx  = map2url($fidxstack,0).$outputpost;
    $_re_f_main = map2url($rstack,0).$outputpost;
    $_re_f_top  = map2url($ftopstack,0).$outputpost;
    $re_f_idx   = rel2outdir($_re_f_idx);
    $re_f_main  = rel2outdir($_re_f_main);
    if ($style_ajax) {
        $re_f_main =~ s/html$/php/;
    } else {
	$re_noajax_comm_s = "<!--";
	$re_noajax_comm_e = "-->";
    }
    my $midx = readfile($templateidx);
    my $mtop = readfile($templatetop);
    $mtop =~ s/¶([^¶]+)¶/$$1/eg;
    $midx =~ s/¶([^¶]+)¶/$$1/eg;
    if ($OPT{'unifyjs'}) {
    } else {
	$midx =~ s/<!--unifyjs-start//g;
	$midx =~ s/unifyjs-end-->//g;
    }
    print ("\tWriting frameset top-htmlfile $outdir$_re_f_top (".filename($_re_f_top).")\n")  if ($OPT{verbose} && !$OPT{'quite'});
    writefile($outdir.filename($_re_f_top),$mtop);
    print ("\tWriting frameset top-frameset-index $outdir$re_f_idx (".filename($_re_f_idx).")\n")  if ($OPT{verbose} && !$OPT{'quite'});
    writefile($outdir.filename($_re_f_idx),$midx);
}	

if ($style_ajax && !$OPT{'dbgoutnomacro'}) {
    if ($OPT{'ajaxfile'}) {
	print("Todo: export structs\n");
    } else {
	$ntbl = $dbh->prepare("DELETE s, e FROM ${re_sajax_prefix}_struct AS s LEFT JOIN ${re_sajax_prefix}_structelem AS e ON s.htmltag_struct_id = e.htmltag_structelem_sid WHERE s.htmltag_struct_fid=? AND s.htmltag_struct_linkid=?");
	$ntbl->execute($htmltag_html_fid,$htmltag_html_linkid);
	$ntbl = $dbh->prepare("delete from ${re_sajax_prefix}_macro where htmltag_macro_fid=?");
	$ntbl->execute($htmltag_html_fid);
	$ctbl = $dbh->prepare("insert into ${re_sajax_prefix}_macro ( htmltag_macro_name, htmltag_macro_mid, htmltag_macro_fid, htmltag_macro_desc ) values (?,?,?,?)");
	foreach my $did (keys %dirs) {
	    my $d = $dirs{$did};
	    my ($n,$dirid,$def) = @$d{'_n','id','def'};
	    $ctbl->execute($n,"M${dirid}",$htmltag_html_fid,$def);
	}
	my $ctbl0 = $dbh->prepare("insert into ${re_sajax_prefix}_struct ( htmltag_struct_id, htmltag_struct_name, htmltag_struct_sid, htmltag_struct_fid, htmltag_struct_linkid, htmltag_struct_desc ) values ('',?,?,?,?,?)");
	my $ctbl1 = $dbh->prepare("insert into ${re_sajax_prefix}_structelem ( htmltag_structelem_id, htmltag_structelem_sid, htmltag_structelem_idx, htmltag_structelem_name, htmltag_structelem_desc, htmltag_structelem_typ ) values ('',?,?,?,?,?)");
	my $ctblsql = $dbh->prepare("SELECT s.htmltag_struct_sid, s.htmltag_struct_name, s.htmltag_struct_linkid, e.htmltag_structelem_name, e.htmltag_structelem_typ, e.htmltag_structelem_idx  FROM ${re_sajax_prefix}_struct as s LEFT JOIN ${re_sajax_prefix}_structelem as e ON s.htmltag_struct_id = e.htmltag_structelem_sid WHERE s.htmltag_struct_name = ? AND s.htmltag_struct_linkid = ? ORDER BY e.htmltag_structelem_idx");
	
	my $checkNewID = $dbh->prepare( 'select last_insert_id()' );
	foreach my $k (keys %structs) {
	    my $struct = $structs{$k};
	    my ($N,$id,$fields) = @$struct{'N','id','fields'};
	    my $match = "0";
	    my ($s_htmltag_struct_sid, $s_htmltag_struct_name, $s_htmltag_struct_linkid, $e_htmltag_structelem_name, $e_htmltag_structelem_typ, $e_htmltag_structelem_idx);
	    if ($OPT{'unifystructs'} && ("struct <unknown>" ne $structsid{$k})) {
		$ctblsql->execute($structsid{$k},$htmltag_html_linkid);
		$ctblsql->bind_columns( \$s_htmltag_struct_sid, \$s_htmltag_struct_name, \$s_htmltag_struct_linkid, \$e_htmltag_structelem_name, \$e_htmltag_structelem_typ, \$e_htmltag_structelem_idx );
		my $idx = 0; 
		$match = $s_htmltag_struct_sid;
		while ( $ctblsql->fetch() ) {
		    print("#### $s_htmltag_struct_sid: $s_htmltag_struct_name, $s_htmltag_struct_linkid, $e_htmltag_structelem_name, $e_htmltag_structelem_typ: $e_htmltag_structelem_idx\n") if ($OPT{'dbgstruct'});
		    my $f = $$fields[$idx];
		    my ($n,$typ) = @$f{'n','typ'};
		    if ($e_htmltag_structelem_name ne $n ||
			$e_htmltag_structelem_typ ne $typ) {
			$match = "0";
			last;
		    }
		    $idx++;
		}
		$match = "0" if (scalar(@$fields) != $idx);
	    }
	    
	    if ($match eq "0") {
		print("New structure ".$structsid{$k}."\n") if ($OPT{'dbgstruct'});
		if ($ctbl0->execute($structsid{$k},$N.$id,$htmltag_html_fid,$htmltag_html_linkid,"")) {
		    $checkNewID->execute() or die("Cant get structs id");
		    my ($newOccuID) = $checkNewID->fetchrow_array; 
		    my $idx = 0;
		    foreach my $f (@$fields) {
			my ($n,$typ) = @$f{'n','typ'};
			$ctbl1->execute($newOccuID,$idx,$n,"",$typ);
			$idx++;
		    }
		}
	    } else {
		print("Reuse structure ".$structsid{$k}." with $s_htmltag_struct_sid\n") if ($OPT{'dbgstruct'});
	    }
	}
    }
}

if ($style_xml) {
    print("Update exportdb $exportdb\n") if $OPT{'verbose'};
    writefile($exportdb,$exportdb_content);
}

sub cmpstr {
    my ($a,$b) = @_;
    $a =~ s/^\s*//;
    $b =~ s/^\s*//;
    $a =~ s/\s*$//;
    $b =~ s/\s*$//;
    return ($a eq $b);
}

# =================================0

sub dumpstruct {
    my ($a) = @_;
    my @a = ();
    foreach my $k(sort keys (%$a)) {
	my $e = $$a{$k};
	push(@a,[_bold($structsid{$k})]);
	foreach my $f (@{$$e{'fields'}}) {
	    push(@a,['',$$f{'typ'},$$f{'n'}]);
	}
    }
    return _alignarray([@a]);
}

sub propagate_line {
    foreach my $l (@l) {
        if (ref($l) eq 'HASH') {
	    if (exists($l->{'lnk'})) {
		$m{$l->{'lnk'}}{'line'} = $l->{'line'};
            }
        } 
    }
    foreach my $mk (@ml) {
        my $m = $m{$mk};
        my @a = @{$$m{'a'}};
        my @b = @{$$m{'b'}}; my $i = 0;
        foreach my $l (@a,@b) {
            if (exists($l->{'lnk'})) {
		$m{$l->{'lnk'}}{'line'} = $m->{'line'};
            }
        }
    }
}

sub dumperdbgpa {
    @fstack = ({'l'=>0});
    my @c = ();
    foreach my $l (@l) {
        my $lm = "";
        if ($OPT{'dbgline'}) {
            print(sprintf("%s@%d",$fstack[$#fstack]{'f'},$fstack[$#fstack]{'l'}));
        }
        if (ref($l) eq 'HASH') {
	    $lm = sprintf("%04d;",$l->{'line'});
            $lm .= $l->{'typ'}.":".$l->{'tok'};
            if (exists($l->{'lnk'})) {
                $lm .="\tmacro:".$l->{'lnk'};
		$m{$l->{'lnk'}}{'line'} = $l->{'line'};
            }
            if (exists($l->{'ref'})) {
                $lm .= "\tref:".$l->{'ref'}{'refdfile'}.'@'.$l->{'ref'}{'refdline'};
            }
        } elsif (ref($l) eq 'BLOCK') {
            $lm = "BLK:\"".$$l{'typ'}."\"";
            if ($$l{'typ'} eq 'fopen') {
                push(@fstack,{'l'=>1,'f'=>$$l{'f'}});
            } elsif ($$l{'typ'} eq 'frename') {
                $fstack[$#fstack]{'f'} = $$l{'f'};
                $fstack[$#fstack]{'l'} = $$l{'l'};
            } elsif ($$l{'typ'} eq 'fclose') {
                pop(@fstack);
                $fstack[$#fstack]{'l'}++;
            }
        } else {
            my $l0 = $l;
	    if (($OPT{'dbgpan'} && $l0=~/^link:/)) {
		next;
	    }
	    my $lcnt = ($l0 =~ tr/\n/\n/);
	    $fstack[$#fstack]{'l'} += $lcnt;
	    $l0 =~ s/\n/\\n/g;
	    $lm = "   :\"$l0\"";
	}
        print($lm."\n");
    }
    
    foreach my $mk (@ml) {
        my $m = $m{$mk};
        printf("%04d:",$$m{'line'});
	print("$mk: ".$$m{'n'}."\n");
        my @a = @{$$m{'a'}};
        my @b = @{$$m{'b'}}; my $i = 0;
        foreach my $l (@a,@b) {
            my $pre = $i < scalar(@a) ? "" : "\t";
            print ($pre."\t".$l->{'typ'}.":".$l->{'tok'});
            if (exists($l->{'lnk'})) {
                print("\tmacro:".$l->{'lnk'});
            }
	    if (exists($l->{'ref'})) {
                print("\tref:".$l->{'ref'}{'refdfile'}.'@'.$l->{'ref'}{'refdline'});
                print("\ttypref:".$l->{'ref'}{'typdfile'}.'@'.$l->{'ref'}{'typdline'}) if (exists($l->{'ref'}{'typdfile'}));
            }
            print ("\n");
            $i++;
        }
    }
}

sub fileout {
    my ($str) = @_;
    if ($OPT{'dbgf'}) {
        my $l = scalar(@fstack);
        print($str.join("",('|') x $l).": ");
        print($fstack[$#fstack]{'f'}."(".$fstack[$#fstack]{'fid'}."->".$fstack[$#fstack]{'pid'}.")");
	
        print("\n");
    }
}



sub dbgstructout {
    foreach my $k (sort keys %structs) {
	my $v = $structs{$k};
	my ($id,$fields) = @$v{'id','fields'};
	print("$id: $k\n");
	foreach my $e (@$fields) {
	    my ($n,$typ) = @$e{'n','typ'};
	    print("\t$n:$typ\n");
	}
    }
}

sub getmatch {
    my ($a,$b) = @_;
    my $al = length($a);
    my $bl = length($b);
    my $l = $al < $bl ? $al : $bl;
    my $i = 0;
    for($i = 0; $i < $l; $i++) {
	if (substr($a,$i,1) ne substr($b,$i,1)) {
	    last;
	}
    }
    return $i;
}

sub indexunify_gather {
    my ($i) = @_;
    my @r = ();
    push(@r,@{$$i{'+'}}) if (exists($$i{'+'}));
    my @k =  grep { $_ ne '+' && $_ ne '-' } keys %$i;
    foreach my $k (@k) {
	push(@r,indexunify_gather($$i{$k}));
    }
    return @r;
}

sub indexunify_count {
    my ($i) = @_;
    my $c = 0;
    $c += scalar(@{$$i{'+'}}) if (exists($$i{'+'}));
    my @k =  grep { $_ ne '+' && $_ ne '-' } keys %$i;
    foreach my $k (@k) {
	$c += indexunify_count($$i{$k});
    }
    return $c;
}

sub indexunify_rec {
    my ($i) = @_;
    my @k =  grep { $_ ne '+' && $_ ne '-' } keys %$i;
    if (indexunify_count($i) < $opt_idxcount) {
	my @r = indexunify_gather($i);
	map { delete($$i{$_}) } @k;
	$$i{'+'} = [@r];
    } else {
	foreach my $k (@k) {
	    indexunify_rec($$i{$k});
	}
    }
}

$indexhtml_id = 1;
sub indexhtml_rec {
    my ($i,$p) = @_;
    my $html = "";
    my @k =  sort grep { $_ ne '+' && $_ ne '-' } keys %$i;
    $$i{'-'} = $indexhtml_id++ if (!exists($$i{'-'}));
    foreach my $k (@k) {
	my $_id = $indexhtml_id++;
	$$i{$k}{'-'} = $_id;
	my $N = "I"; my @a = ();
	$html .= "<div id=\"V${N}--xmlid--${_id}\" class=\"typbu\">";
	if ($style_xml) {
	    $func = "xmlload";
	    my $f = gettoolxmlfilename("${N}${_id}");
	    push(@a,"'$f'","'${N}${_id}'");
	} else {
	    $func = "load";
	    push(@a,"'${N}${_id}'");
	}
	$html .= "<a class=\"typb\" id=\"A${N}--xmlid--${_id}\" href=\"javascript:${func}('${N}--xmlid--${_id}',".join(",",@a).");\" id=\"A--xmlid--$id\" title=\"${func}('--xmlid--$_id',".join(",",@a).");\" >[+]</a>";
	$html .= "$p$k</div>";
	$html .= "<div id=\"I${N}--xmlid--${_id}\"  class=\"typbu\">";
	indexhtml_rec($$i{$k},$p.$k);
	$html .= "</div>";
    }
    if (exists($$i{'+'})) {
	my @e = @{$$i{'+'}};
	foreach my $e (@e) {
	    my ($id,$n) = @$e{'id','n'};
	    my $N = "B"; my @a = ();
	    $html .= "<div id=\"VB${id}\" class=\"typbu\">";
	    if ($style_xml) {
		$func = "xmltypebrowserexp";
		my $f = gettoolxmlfilename("${N}$id");
		push(@a,"'$f'","'${N}${id}'");
	    } else {
		$func = "typebrowserexp";
		push(@a,"'${N}${id}'");
	    }
	    $html .= "<a class=\"typb\" id=\"A${N}--xmlid--${id}\" href=\"javascript:${func}('--xmlid--${id}',".join(",",@a).");\" id=\"A${N}--xmlid--$id\" title=\"${func}('--xmlid--$id',".join(",",@a).");\" >[+]</a>";
	    $html .= $n;
	    $html .= "</div>";
	    $html .= "<div id=\"V${N}--xmlid--${id}\" class=\"typbu\">";
	    $html .= "<div id=\"I${N}--xmlid--${id}\" class=\"typbu\">";
	    $html .= "</div>";
	    $html .= "</div>";
	}
    }
    my $N = "I"; my @a = (); my $func = "";
    $_id = $$i{'-'};
    if ($style_xml) {
	$func = "xmlload";
	my $f = gettoolxmlfilename("${N}$_id");
	$gctx{'xml'}{$f} .= "<${N}${_id}>".xmlsplitlines($html)."</${N}${_id}>\n";
	push(@a,"'$f'","'${N}${_id}'");
    } else {
	$func = "load";
	my ($o,$c) = ($struct_divo,$struct_divc);
	$re_id = $N.$_id;
	$o =~ s/¶([^¶]+)¶/$$1/eg;
	$c =~ s/¶([^¶]+)¶/$$1/eg;
	$re_struct .= "\n".$o."<span style=\"color:#000000;\">".$html."<span>".$c;
	push(@a,"'${re_id}'");
    }
    return ("${N}${_id}","<a class=\"typb\" id=\"A${N}--xmlid--${_id}\" href=\"javascript:${func}('${N}--xmlid--${_id}',".join(",",@a).");\" id=\"A${N}--xmlid--${_id}\" title=\"${func}('A${N}--xmlid--${_id}',".join(",",@a).");\" >[+]</a>");
}

sub indexadd_rec {
    my ($i,$n,$a) = @_;
    my $l = length($n);
    foreach my $k (grep { $_ ne '+' && $_ ne '-' } keys %$i) {
	my $v = $$i{$k};
	my $j = getmatch($n,$k);
	if ($j)  {
	    my $k_pre  = substr($k,0,$j);
	    my $k_post = substr($k,$j);
	    my $n_pre  = substr($n,0,$j);
	    my $n_post = substr($n,$j);
	    die("Unmatched keys") if ($k_pre ne $n_pre);
	    if (length($k_post) != 0) {
		$$i{$k_pre}{$k_post}{'+'} = $$v{'+'};
		delete($$i{$k});
	    }
	    
	    if (length($n_post) > 0) {
		indexadd_rec($$i{$k_pre},$n_post,$a);
	    } else {
		$$i{$k_pre}{"+"} = $a;
	    }
	    return;
	}
    }
    $$i{$n}{'+'} = $a;
}

sub createindex {
    my ($i) = @_;
    my %rec = ();
    foreach my $k (keys %$i) {
	indexadd_rec(\%rec,$k,$$i{$k});
    }
    indexunify_rec(\%rec);
    return \%rec;
}

sub read_exportdb {
    my $e = "";
    $e = readfile($exportdb) if (-f $exportdb);
    die("file $exportdb not a export database\n") if (!(length($e) == 0 || $e =~ /^<links>/));
    $exportdb_content = $e;
    if (length($exportdb_content) == 0) {
	$exportdb_content = "<links>\n</links>\n";
    }
}

# cleanse forward references
sub cleanse_export {
    my ($n) = @_;
    my @e = (); my $f = 0;
    for (my $i = scalar(@do_export)-1; $i >= 0; $i--) {
	if ($f) {
	    if ($do_export[$i][0] ne $n) {
		push(@e, $do_export[$i]);
	    }
	} else {
	    push(@e, $do_export[$i]);
	    if ($do_export[$i][0] eq $n) {
		$f = 1;
	    }
	}
    }
    @do_export = @e;
}



if ($dbhwiki) {
    $dbhwiki->disconnect();
}
if ($dbh) {
    $dbh->disconnect();
}






















