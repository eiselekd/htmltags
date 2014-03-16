
use DBI;

$dbhwiki = undef;
if ($mediawiki) {
    #print("DBI:mysql:$re_mediawiki_server:$re_mediawiki_db,$re_mediawiki_user,$re_mediawiki_pass\n"); 
    $dbhwiki = DBI->connect("DBI:mysql:$re_mediawiki_db:$re_mediawiki_server",$re_mediawiki_user,$re_mediawiki_pass); 
}

#http://upload.wikimedia.org/wikipedia/commons/4/41/Mediawiki-database-schema.png

my $tv = getTimestamp();

sub getTimestamp {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time());
    my $tv = sprintf("%4d%02d%02d%02d%02d%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $tv;
}

sub wikiwrap {
    my ($m,$id,$lid,$n) = @_;
    return "<cfw_src id=\"$id\" linkid=\"$lid\" name=\"$n\"></cfw_stc>";
}

sub wikititle {
    my ($n) = @_;
    $n =~ s/[\-_]/-/g;
    return uc(substr($n,0,1)).substr($n,1);
}

#deleteArticle(0,"Testm",$prefix);
#insertArticle(0,"Testm",$prefix, "Test text");

sub deleteRow {
    my ($prefix,$sql, $id, $str) = @_;
    my $sqh = $dbhwiki->prepare( $sql );
    my $cnt = $sqh->execute($id);
    $sqh->finish();
    if ($OPT{'wikiverbose'}) {
	printf ("%20s:%d rows deleted\n",$str,$cnt) if ($cnt);
    }
}

sub insertArticle {
    my ($namespace,$title,$prefix,$text) = @_;
    my $sqlin = qq{
INSERT INTO ${prefix}page (
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

    my $sqlinh = $dbhwiki->prepare( $sqlin );
    my $cnt = $sqlinh->execute(NULL,$namespace,$title,rand(),getTimestamp());
    $sqlinh->finish();
    my $id = $dbhwiki->last_insert_id(undef, undef, "${prefix}page", undef);
    my $sqlintext = qq{
INSERT INTO ${prefix}text (
old_id,        
old_text,      
old_flags
) VALUES ( ?, ?, ?); };
    my $sqlintexth = $dbhwiki->prepare( $sqlintext );
    my $cnt = $sqlintexth->execute(NULL,$text,0);
    $sqlintexth->finish();
    my $textid = $dbhwiki->last_insert_id(undef, undef, "${prefix}text", undef);
    
    my $sqlinrev = qq{
INSERT INTO ${prefix}revision (
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
    my $sqlinrevh = $dbhwiki->prepare( $sqlinrev );
    my $tv = getTimestamp();
    my $cnt = $sqlinrevh->execute(NULL,$id,$textid,"Comment",$tv);
    $sqlinrevh->finish();
    my $revid = $dbhwiki->last_insert_id(undef, undef, "${prefix}revision", undef);

    if ($OPT{'quite'} && $title =~ /\.c\./ && !$OPT{'quite_done'}) {
	print("  HTMLTAG \[\[$title]]\n");
	$OPT{'quite_done'} = 1;
    }
    print("Created Article [$namespace:\033[1m[[$title]]\033[0m] with id $id: Textid=$textid, Revid=$revid Timestamp=$tv\n") if ($OPT{'verbose'} && !$OPT{'quite'});

    
    my $sqlup = qq{
    UPDATE ${prefix}page page SET 
				page_latest = ?,       
				page_touched = ?,    
				page_is_new = 1,      
				page_is_redirect = 0, 
				page_len = ?
    WHERE page.page_id = ?
    };
    
    my $sqluph = $dbhwiki->prepare( $sqlup );
    my $cnt = $sqluph->execute($revid,getTimestamp(),length($text),$id);
    $sqluph->finish();

}

sub deleteArticle {
    my ($namespace,$tile,$prefix ) = @_;

    my $sqllog = qq{DELETE log FROM ${prefix}logging log WHERE log.log_namespace = ? AND log.log_title = ? };
    my $sqllogh = $dbhwiki->prepare( $sqllog );
    my $cnt = $sqllogh->execute($namespace,$tile);
    $sqllogh->finish();
    if ($OPT{'wikiverbose'}) {
	printf ("%20s:%d rows deleted\n","Logs",$cnt) if ($cnt);
	}
	
    my $sql = qq{ SELECT page_id  FROM ${prefix}page WHERE page_namespace = ? AND page_title = ? };
    my $sth = $dbhwiki->prepare( $sql );
    $sth->execute($namespace,$tile);
    my( $id );
    $sth->bind_columns( \$id );
    my $updatecnt = 0;
    while ( $sth->fetch() ) {
	
	my $sqld20 = qq{
    DELETE ar, rev, text
	FROM ((${prefix}archive ar RIGHT JOIN ${prefix}revision rev ON ar.ar_rev_id = rev.rev_id) LEFT JOIN ${prefix}text text ON rev.rev_text_id = text.old_id) 
	WHERE rev.rev_page = ?
    };
	my $sqlh20 = $dbhwiki->prepare( $sqld20 );
	my $cnt = $sqlh20->execute($id);
	$sqlh20->finish();
	if ($cnt) {
	    print ("Archive-Revision-Text: $cnt rows deleted\n") if ($OPT{'wikiverbose'});
	}
	
	#$dbw->delete( 'page', array( 'page_id' => $id ), __METHOD__);
	deleteRow($prefix, qq{ DELETE FROM ${prefix}page WHERE page_id = ?}, $id,"Page");
	# Delete restrictions for it
	deleteRow($prefix, qq{ DELETE FROM ${prefix}page_restrictions WHERE pr_page = ?}, $id,"Pagerestrictions");
	#$dbw->delete( 'revision', array( 'rev_page' => $id ), __METHOD__ );
	deleteRow($prefix, qq{ DELETE FROM ${prefix}revision WHERE rev_page = ?}, $id,"Revisions");
	#$dbw->delete( 'trackbacks', array( 'tb_page' => $id ), __METHOD__ );
	deleteRow($prefix, qq{ DELETE FROM ${prefix}trackbacks WHERE tb_page = ?}, $id,"Trackbacks");
	
	#$dbw->delete( 'pagelinks', array( 'pl_from' => $id ) );
	my $sqlq30 = qq{ SELECT pl_from FROM ${prefix}pagelinks WHERE pl_namespace = ? AND pl_title = ? };
	my $sthq30 = $dbhwiki->prepare( $sqlq30 );
	$updatecnt += $sthq30->execute($namespace, $tile);
	my( $pageid );
	$sthq30->bind_columns( \$pageid );
	while ( $sthq30->fetch() ) {
	    my $sqlu = qq{ UPDATE ${prefix}page SET page_touched = ? where page_id = ? };
	    my $sthu = $dbhwiki->prepare( $sqlu );
	    
	    my $cnt = $sthu->execute(getTimestamp(),$pageid);
	    if ($cnt) {
		print ("Updated pages       : $cnt for page $pageid with ".getTimestamp()."\n") if ($OPT{'wikiverbose'});
	    }
	    $sthu->finish();
	}
	$sthq30->finish();
	
	#$dbw->delete( 'pagelinks', array( 'pl_from' => $id ) );
	deleteRow($prefix, qq{ DELETE FROM ${prefix}pagelinks WHERE pl_from = ?}, $id,"Pagelinks");
	#$dbw->delete( 'revision', array( 'rev_page' => $id ), __METHOD__ );
	deleteRow($prefix, qq{ DELETE FROM ${prefix}revision WHERE rev_page = ?}, $id,"Revisions");
	#$dbw->delete( 'imagelinks', array( 'il_from' => $id ) );
	deleteRow($prefix, qq{ DELETE FROM ${prefix}imagelinks WHERE il_from = ?}, $id,"Imagelinks");
	#$dbw->delete( 'categorylinks', array( 'cl_from' => $id ) );
	deleteRow($prefix, qq{ DELETE FROM ${prefix}categorylinks WHERE cl_from = ?}, $id,"Categorylinks");
	#$dbw->delete( 'templatelinks', array( 'tl_from' => $id ) );
	deleteRow($prefix, qq{ DELETE FROM ${prefix}templatelinks WHERE tl_from = ?}, $id,"Templatelinks");
	#$dbw->delete( 'externallinks', array( 'el_from' => $id ) );
	deleteRow($prefix, qq{ DELETE FROM ${prefix}externallinks WHERE el_from = ?}, $id,"Externallinks");
	#$dbw->delete( 'langlinks', array( 'll_from' => $id ) );
	deleteRow($prefix, qq{ DELETE FROM ${prefix}langlinks WHERE ll_from = ?}, $id,"Langlinks");
	#$dbw->delete( 'redirect', array( 'rd_from' => $id ) );
	deleteRow($prefix, qq{ DELETE FROM ${prefix}redirect WHERE rd_from = ?}, $id,"Redirect");

    }
    $sth->finish();
    if ($updatecnt) {
	print ("Updated pages       : $updatecnt\n") if ($OPT{'wikiverbose'});
    }
}


#    $dbhwiki->disconnect();
    
#    exit(0);
    
    

































1
