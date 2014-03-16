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


\n"); exit(1); }
sub optio { print("$0 <infiles> \n"); exit(1); }

Getopt::Long::Configure(qw(bundling));
GetOptions(\%OPT,qw{
    verbose|v+
    options
    outdir|d=s
    output|o=s
    template|t=s
    templatejs=s
    templatetop|t=s
    templateidx|t=s
    templatereload=s
    serverprefix=s
    serverroot=s
    style|s=s
    ajaxserver|s=s
    ajaxuser|s=s
    ajaxpass|s=s
    ajaxdb|s=s
    ajaxdbprefix|s=s
    xml|x=s
    linkid=s
    fid=s
    xmlfilesize|i=s
    pastecheck
    silent
    dbgpa dbgpan
    dbgma=s
    idxcount=s
    dbgm dbgmid
    dbgl
    dbgdef dbgref dbgrefs
    dbgpaste
    dbgfile
    dbgline
    dbglink
    dbgtok=s
    dbgtoken dbgdir dbgidreg norec
    dbgjs dbgstruct dbgmdom
    dbgprocess dbgdecl dbgtool
    dbgf dbgfopen dbgaux
    nocompress styles-from-export print-from-export
},@g_more) or usage(\*STDERR);

if (exists($OPT{'print-from-export'})) {
    print("htmltag.pl options:\n");
    exit(0);
    
} elsif (exists($OPT{'styles-from-export'})) {
    my $r = "";
    if (exists($ENV{'CONFIG_HTMLTAG_TYPE'})) {

	sub instring {
	    my ($str) = @_;
	    return "\"$str\"";
	}
	
	if ($ENV{'CONFIG_HTMLTAG_TYPE'} =~ m/HTMLTAG_SIMPLE/) {
	    $r .= " --style=simple";
	    $r .= ",multipage " if (exists($ENV{'CONFIG_HTMLTAG_MULTIPAGE'}) && ($ENV{'CONFIG_HTMLTAG_MULTIPAGE'} eq 'true' || $ENV{'CONFIG_HTMLTAG_MULTIPAGE'} == 1) );
	    $r .= " ";
	} elsif ($ENV{'CONFIG_HTMLTAG_TYPE'} =~ m/HTMLTAG_AJAX/) {
	    $r .= " --style=ajax";
	    $r .= ",multipage " if (exists($ENV{'CONFIG_HTMLTAG_MULTIPAGE'}) && ($ENV{'CONFIG_HTMLTAG_MULTIPAGE'} eq 'true' || $ENV{'CONFIG_HTMLTAG_MULTIPAGE'} == 1) );
	    $r .= " ";
	    $r .= " --ajaxserver=".instring($ENV{'CONFIG_HTMLTAG_AJAX_DBSERVER'}) if (exists($ENV{'CONFIG_HTMLTAG_AJAX_DBSERVER'}) && length($ENV{'CONFIG_HTMLTAG_AJAX_DBSERVER'}));
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
	}
	$r .= " --serverprefix=".instring($ENV{'CONFIG_HTMLTAG_SERVER_PREFIX'}) if (exists($ENV{'CONFIG_HTMLTAG_SERVER_PREFIX'}) && length($ENV{'CONFIG_HTMLTAG_SERVER_PREFIX'}));
	$r .= " --serverroot=".instring($ENV{'CONFIG_HTMLTAG_SERVER_ROOT'}) if (exists($ENV{'CONFIG_HTMLTAG_SERVER_ROOT'}) && length($ENV{'CONFIG_HTMLTAG_SERVER_ROOT'}));
	
    }
    print("\n########################\n# options for $Bin/".basename($0)." (called from gcc)\n");
    print(_alignarray([map { ["#",$_.":",$ENV{$_}] } grep { exists($ENV{$_}) } grep { $_ =~ m/HTMLTAG/ } keys %ENV]));
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

    $re_sajax_server = $ajaxserver = $OPT{'ajaxserver'} || "localhost";
    $re_sajax_user = $ajaxuser = $OPT{'ajaxuser'} || "root";
    $re_sajax_pass = $ajaxpass = $OPT{'ajaxpass'} || "";
    $re_sajax_db = $ajaxdb = $OPT{'ajaxdb'} || "wikidb";
    $re_sajax_prefix = $OPT{'ajaxdbprefix'} || "mediawiki";
    
    $re_sajax_php =~ s/¶([^¶]+)¶/$$1/eg;

    use DBI; 
    $dbh = DBI->connect("DBI:mysql:$ajaxdb:$ajaxserver",$ajaxuser,$ajaxpass); 

#http://upload.wikimedia.org/wikipedia/commons/4/41/Mediawiki-database-schema.png
    my $tv = getTimestamp();

sub getTimestamp {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time());
    my $tv = sprintf("%4d%02d%02d%02d%02d%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $tv;
}

deleteArticle(0,"Testm",$re_sajax_prefix);
insertArticle(0,"Testm",$re_sajax_prefix, "Test text");

sub deleteRow {
    my ($re_sajax_prefix,$sql, $id, $str) = @_;
    my $sqh = $dbh->prepare( $sql );
    my $cnt = $sqh->execute($id);
    $sqh->finish();
    printf ("%20s:%d rows deleted\n",$str,$cnt) if ($cnt);
}

sub insertArticle {
    my ($namespace,$title,$re_sajax_prefix, $text ) = @_;
    my $sqlin = qq{
INSERT INTO ${re_sajax_prefix}page (
page_id ,
page_namespace ,
page_title ,
page_counter ,
page_restrictions ,
page_is_redirect ,
page_is_new ,
page_random ,
page_touched ,
page_latest ,
page_len
)
VALUES (
? , ?, ?, '0', '', '0', '0', ?, ?, 0, 0
);
};

    my $sqlinh = $dbh->prepare( $sqlin );
    my $cnt = $sqlinh->execute(NULL,$namespace,$title,rand(),getTimestamp());
    $sqlinh->finish();
    my $id = $dbh->last_insert_id(undef, undef, "${re_sajax_prefix}page", undef);
    my $sqlintext = qq{
INSERT INTO ${re_sajax_prefix}text (
old_id,        
old_text,      
old_flags
) VALUES ( ?, ?, ?); };
    my $sqlintexth = $dbh->prepare( $sqlintext );
    my $cnt = $sqlintexth->execute(NULL,$text,0);
    $sqlintexth->finish();
    my $textid = $dbh->last_insert_id(undef, undef, "${re_sajax_prefix}text", undef);
    
    my $sqlinrev = qq{
INSERT INTO ${re_sajax_prefix}revision (
rev_id,        
rev_page,      
rev_text_id,   
rev_comment,   
rev_minor_edit,
rev_user,      
rev_user_text, 
rev_timestamp, 
rev_deleted,   
rev_len	
) VALUES ( ?, ?, ?, ?, 0, 1, 'Eiselekd', ?, 0, 10); };
    my $sqlinrevh = $dbh->prepare( $sqlinrev );
    my $tv = getTimestamp();
    my $cnt = $sqlinrevh->execute(NULL,$id,$textid,"Comment",$tv);
    $sqlinrevh->finish();
    my $revid = $dbh->last_insert_id(undef, undef, "${re_sajax_prefix}revision", undef);
    
    print("Created Article [$namespace:$title] with id $id: Textid=$textid, Revid=$revid Timestamp=$tv\n");

    
    my $sqlup = qq{
    UPDATE ${re_sajax_prefix}page page SET 
				page_latest = ?,       
				page_touched = ?,    
				page_is_new = 1,      
				page_is_redirect = 0, 
				page_len = ?
    WHERE page.page_id = ?
    };
    
    my $sqluph = $dbh->prepare( $sqlup );
    my $cnt = $sqluph->execute($revid,getTimestamp(),length($text),$id);
    $sqluph->finish();

}

sub deleteArticle {
    my ($namespace,$tile,$re_sajax_prefix ) = @_;

    my $sqllog = qq{DELETE log FROM ${re_sajax_prefix}logging log WHERE log.log_namespace = ? AND log.log_title = ? };
    my $sqllogh = $dbh->prepare( $sqllog );
    my $cnt = $sqllogh->execute($namespace,$tile);
    $sqllogh->finish();
    printf ("%20s:%d rows deleted\n","Logs",$cnt) if ($cnt);
    
    my $sql = qq{ SELECT page_id  FROM ${re_sajax_prefix}page WHERE page_namespace = ? AND page_title = ? };
    my $sth = $dbh->prepare( $sql );
    $sth->execute($namespace,$tile);
    my( $id );
    $sth->bind_columns( \$id );
    my $updatecnt = 0;
    while ( $sth->fetch() ) {
	
	my $sqld20 = qq{
    DELETE ar, rev, text
	FROM ((${re_sajax_prefix}archive ar RIGHT JOIN ${re_sajax_prefix}revision rev ON ar.ar_rev_id = rev.rev_id) LEFT JOIN ${re_sajax_prefix}text text ON rev.rev_text_id = text.old_id) 
	WHERE rev.rev_page = ?
    };
	my $sqlh20 = $dbh->prepare( $sqld20 );
	my $cnt = $sqlh20->execute($id);
	$sqlh20->finish();
	if ($cnt) {
	    print ("Archive-Revision-Text: $cnt rows deleted\n");
	}
	
	#$dbw->delete( 'page', array( 'page_id' => $id ), __METHOD__);
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}page WHERE page_id = ?}, $id,"Page");
	# Delete restrictions for it
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}page_restrictions WHERE pr_page = ?}, $id,"Pagerestrictions");
	#$dbw->delete( 'revision', array( 'rev_page' => $id ), __METHOD__ );
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}revision WHERE rev_page = ?}, $id,"Revisions");
	#$dbw->delete( 'trackbacks', array( 'tb_page' => $id ), __METHOD__ );
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}trackbacks WHERE tb_page = ?}, $id,"Trackbacks");
	
	#$dbw->delete( 'pagelinks', array( 'pl_from' => $id ) );
	my $sqlq30 = qq{ SELECT pl_from FROM ${re_sajax_prefix}pagelinks WHERE pl_namespace = ? AND pl_title = ? };
	my $sthq30 = $dbh->prepare( $sqlq30 );
	$updatecnt += $sthq30->execute($namespace, $tile);
	my( $pageid );
	$sthq30->bind_columns( \$pageid );
	while ( $sthq30->fetch() ) {
	    my $sqlu = qq{ UPDATE ${re_sajax_prefix}page SET page_touched = ? where page_id = ? };
	    my $sthu = $dbh->prepare( $sqlu );
	    
	    my $cnt = $sthu->execute(getTimestamp(),$pageid);
	    if ($cnt) {
		print ("Updated pages       : $cnt for page $pageid with ".getTimestamp()."\n");
	    }
	    $sthu->finish();
	}
	$sthq30->finish();
	
	#$dbw->delete( 'pagelinks', array( 'pl_from' => $id ) );
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}pagelinks WHERE pl_from = ?}, $id,"Pagelinks");
	#$dbw->delete( 'revision', array( 'rev_page' => $id ), __METHOD__ );
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}revision WHERE rev_page = ?}, $id,"Revisions");
	#$dbw->delete( 'imagelinks', array( 'il_from' => $id ) );
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}imagelinks WHERE il_from = ?}, $id,"Imagelinks");
	#$dbw->delete( 'categorylinks', array( 'cl_from' => $id ) );
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}categorylinks WHERE cl_from = ?}, $id,"Categorylinks");
	#$dbw->delete( 'templatelinks', array( 'tl_from' => $id ) );
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}templatelinks WHERE tl_from = ?}, $id,"Templatelinks");
	#$dbw->delete( 'externallinks', array( 'el_from' => $id ) );
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}externallinks WHERE el_from = ?}, $id,"Externallinks");
	#$dbw->delete( 'langlinks', array( 'll_from' => $id ) );
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}langlinks WHERE ll_from = ?}, $id,"Langlinks");
	#$dbw->delete( 'redirect', array( 'rd_from' => $id ) );
	deleteRow($re_sajax_prefix, qq{ DELETE FROM ${re_sajax_prefix}redirect WHERE rd_from = ?}, $id,"Redirect");

    }
    $sth->finish();
    if ($updatecnt) {
	print ("Updated pages       : $updatecnt\n");
    }
}


    $dbh->disconnect();
    
    exit(0);
    
    















$dbw->delete( 'page', array( 'page_id' => $id ), __METHOD__);


my $sql = qq{ SELECT old_id, old_text, old_flags FROM mediawikitext };
my $sth = $dbh->prepare( $sql );
$sth->execute();

my( $id, $text, $flags );
$sth->bind_columns( \$id, \$text, \$flags );
while( $sth->fetch() ) {
    print "########### $id #################\n$text\n";
}

$sth->finish();
$dbh->disconnect();



















