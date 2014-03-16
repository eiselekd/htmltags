$RE_comment_Cpp =                q{(?:\/\*(?:(?!\*\/)[\s\S])*\*\/|\/\/[^\n]*\n)};
$RE_string =                     qr{"((?:\\.|[^\\"])*)"};
$RE_string_one =                 qr{'((?:\\.|[^\\'])*)'}; #"
$c_id =                          qr{(?:[a-zA-Z_][a-zA-Z_0-9]*)};

sub quote {
    my ($l) = @_;
    $l =~ s/\n/\\n/g;
    return $l;
}

sub tokenize {
    my ($l,$moff, $m, $fstack) = @_;
    my @l = (); my @c = ();
    pos($l) = 0;
    while(pos($l) < length($l)) {
        my $spc = "";
        pos($$m) = $moff + pos($l);
        if ($$m =~ /\G(?:[ \t]+|$RE_comment_Cpp)+/gc) {
            $spc = $&;
            if ($spc =~ /\n/) {
                push(@l,{'tok'=>$&,typ=>'CMT'});
            }
            pos($l) = pos($$m)-$moff;
        }
        if (pos($l) < length($l)) {
            if ($l =~ /\G$c_id/gc) {
                print("ID : $&\n") if ($OPT{'dbgtoken'});
		my $tok = {'tok'=>$&,typ=>'TOK'};
		foreach my $k ("const", "volatile", "if", "else", "for", "while",
			       "switch", "case", "default", "return", "typedef", "enum", "struct",
			       "union") {
		    if ($& eq $k) {
			$$tok{'col'} = 'c_keyw';
			last;
		    }
		}
		foreach my $k ("int", "long", "char", "unsigned", "short") {
		    if ($& eq $k) {
			$$tok{'col'} = 'c_typid';
			last;
		    }
		}
		$$tok{'col'} = 'c_null' if ($k eq 'NULL');
                push(@l,$tok);
            } elsif ($l =~ /\G[0-9][x]?[0-9a-zA-Z]*/gc) {
                print("TOK: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'TOK'});
            } elsif ($l =~ /\G[\(\),;]/gc) {
                print("GRP: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'GRP'});
            } elsif ($l =~ /\G[\[\]\}\{]/gc) {
                print("BLK: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'BLK'});
            } elsif ($l =~ /\G->\*/gc ||
                     $l =~ /\G\.\*/gc ||
                     $l =~ /\G->/gc ||
                     $l =~ /\G\.\.\./gc ||
                     $l =~ /\G\./gc
                ) {
                print("GRP: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'GRP'});
            } elsif ($l =~ /\G<=/gc ||
                     $l =~ /\G>=/gc ||
                     $l =~ /\G==/gc ||
                     $l =~ /\G!=/gc ||
                     $l =~ /\G\|\|/gc ||
                     $l =~ /\G&&/gc 
                ) {
                print("BOP: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'BOP'});
            } elsif ($l =~ /\G-=/gc ||
                     $l =~ /\G\+=/gc ||
                     $l =~ /\G\*=/gc ||
                     $l =~ /\G\/=/gc ||
                     $l =~ /\G%=/gc ||
                     $l =~ /\G&=/gc ||
                     $l =~ /\G\^=/gc ||
                     $l =~ /\G\|=/gc ||
                     $l =~ /\G>>=/gc ||
                     $l =~ /\G<<=/gc ||
                     $l =~ /\G\+\+/gc ||
                     $l =~ /\G--/gc ||
                     $l =~ /\G<</gc ||
                     $l =~ /\G>>/gc ||
                     $l =~ /\G##/gc
                ) {
                print("AOP: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'AOP'});
            } elsif ($l =~ /\G##/gc) {
                print("TRI: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'TRI'});
            } elsif ($l =~ /\G$RE_string/gc) {
                print("STR: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'STR'});
            } elsif ($l =~ /\G$RE_string_one/gc) {
                print("STR: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'STR'});
            } elsif ($l =~ /\G[\|:\+\-\/\*!\?&<>=%\^~]/gc) {
                print("AOP: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'AOP'});
            } elsif ($l =~ /\G$RE_comment_Cpp/gc) {
                print("CMT: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'CMT'});
            } elsif ($l =~ /\G#[a-zA-Z_]+\s+((?:\\.|[^\\\n])*)\n/sgc) {
                print("DIR: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'DIR','col'=>'c_macn'});
            } elsif ($l =~ /\G#\s*[a-zA-Z_]+\s+((?:<[^>]*>|"[^"]*"))/sgc) {
                print("DIR: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'DIR','col'=>'c_macn'});
            } elsif ($l =~ /\G#\s*(?:ifdef|if|else|elif|endif|define|undef)\s*/sgc) {
                print("BDI: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'BDI','col'=>'c_macn'});
            } elsif ($l =~ /\G#\s*pragma\s*[^\n]*\n?/sgc) {
                print("DIR: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'DIR','col'=>'c_macn'});
            } elsif ($l =~ /\G#\s*ifdef\s+/sgc) {
                print("BDI: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'BDI'});
            } elsif ($l =~ /\G#\s*include\s+/sgc) { # probably a #define a "file" + "#include a" 
                print("DIR: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'DIR','col'=>'c_macn','inc_macro'=>1});
		
            } elsif ($l =~ /\G\$[0-9]+\s*/gc) { # assembler $1 tokens in define
                print("STR: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'STR'});
            } elsif ($l =~ /\G\\$/sgcm) {
                print("NLN: $&\n") if ($OPT{'dbgtoken'});
                push(@l,{'tok'=>$&,typ=>'NLN'});
            } else {
                my $p = substr($l,0,pos($l));
                my $pcnt = $$fstack{'l'} + ($p =~ tr/\n/\n/);
		my $_len = length($l);
                $l = substr($l,pos($l),300);
                print($$fstack{'f'}." line $pcnt: Cant tokenize \"$l\"".($_len > 300 ? "..." : "")." \n") if (!$OPT{'silent'});
		print "So far scanned:\n".DumpTokens(\@l) if (!$OPT{'silent'});
                last;
            }
            if (length($spc)) {
                $l[$#l]{'spc'} = $spc;
            }
        }
    }
    print _bold("Tokens:\n")._alignarray(\@c) if ($OPT{'dbgtoken'});
    return @l;
}



1;

__DATA__
#define TTYPE_TABLE							\
  OP(AOP, EQ,		"=")						\
  OP(AOP, NOT,		"!")						\
  OP(AOP, GREATER,		">")	/* compare */				\
  OP(AOP, LESS,		"<")						\
  OP(AOP, PLUS,		"+")	/* math */				\
  OP(AOP, MINUS,		"-")						\
  OP(AOP, MULT,		"*")						\
  OP(AOP, DIV,		"/")						\
  OP(AOP, MOD,		"%")						\
  OP(AOP, AND,		"&")	/* bit ops */				\
  OP(AOP, OR,		"|")						\
  OP(AOP, XOR,		"^")						\
  OP(AOP, RSHIFT,		">>")						\
  OP(AOP, LSHIFT,		"<<")						\
									\
  OP(BOP, COMPL,		"~")						\
  OP(BOP, AND_AND,		"&&")	/* logical */				\
  OP(BOP, OR_OR,		"||")						\
  OP(AOP, QUERY,		"?")						\
  OP(AOP, COLON,		":")						\
  OP(GRP, COMMA,		",")	/* grouping */				\
  OP(GRP, OPEN_PAREN,	"(")						\
  OP(GRP, CLOSE_PAREN,	")")						\
  TK(PAD, EOF,		NONE)						\
  OP(BOP, EQ_EQ,		"==")	/* compare */				\
  OP(BOP, NOT_EQ,		"!=")						\
  OP(BOP, GREATER_EQ,	">=")						\
  OP(BOP, LESS_EQ,		"<=")						\
									\
  /* These two are unary + / - in preprocessor expressions.  */		\
  OP(AOP, PLUS_EQ,		"+=")	/* math */				\
  OP(AOP, MINUS_EQ,		"-=")						\
									\
  OP(AOP, MULT_EQ,		"*=")						\
  OP(AOP, DIV_EQ,		"/=")						\
  OP(AOP, MOD_EQ,		"%=")						\
  OP(AOP, AND_EQ,		"&=")	/* bit ops */				\
  OP(AOP, OR_EQ,		"|=")						\
  OP(AOP, XOR_EQ,		"^=")						\
  OP(AOP, RSHIFT_EQ,		">>=")						\
  OP(AOP, LSHIFT_EQ,		"<<=")						\
  /* Digraphs together, beginning with CPP_FIRST_DIGRAPH.  */		\
  OP(TRI, HASH,		"#")	/* digraphs */				\
  OP(TRI, PASTE,		"##")						\
  OP(BLK, OPEN_SQUARE,	"[")						\
  OP(BLK, CLOSE_SQUARE,	"]")						\
  OP(BLK, OPEN_BRACE,	"{")						\
  OP(BLK, CLOSE_BRACE,	"}")						\
  /* The remainder of the punctuation.	Order is not significant.  */	\
  OP(GRP, SEMICOLON,		";")	/* structure */				\
  OP(GRP, ELLIPSIS,		"...")						\
  OP(AOP, PLUS_PLUS,		"++")	/* increment */				\
  OP(AOP, MINUS_MINUS,	"--")						\
  OP(GRP, DEREF,		"->")	/* accessors */				\
  OP(GRP, DOT,		".")						\
  OP(GRP, SCOPE,		"::")						\
  OP(GRP, DEREF_STAR,	"->*")						\
  OP(GRP, DOT_STAR,		".*")						\
  OP(GRP, ATSIGN,		"@")  /* used in Objective-C */			\

