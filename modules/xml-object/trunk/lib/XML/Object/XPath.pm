####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package XML::Object::XPath;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module Parse::Yapp::Driver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.05';
$COMPATIBLE = '0.07';
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------




sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'and_expr' => 9,
			'equality_expr' => 10,
			'additive_expr' => 12,
			'location_path' => 13,
			'step' => 15,
			'relational_expr' => 16,
			'function_call' => 17,
			'multiplicative_expr' => 18,
			'or_expr' => 19,
			'unary_expr' => 22,
			'expr' => 25,
			'path_expr' => 26,
			'absolute_location_path' => 29,
			'axis' => 28
		}
	},
	{#State 1
		ACTIONS => {
			'VBAR' => 30
		},
		DEFAULT => -25
	},
	{#State 2
		DEFAULT => -53
	},
	{#State 3
		ACTIONS => {
			'SLASH' => 31,
			'SLASH_SLASH' => 32
		},
		DEFAULT => -34
	},
	{#State 4
		DEFAULT => -48,
		GOTOS => {
			'predicates' => 33
		}
	},
	{#State 5
		DEFAULT => -50
	},
	{#State 6
		ACTIONS => {
			'COLON_COLON' => 34
		}
	},
	{#State 7
		DEFAULT => -44
	},
	{#State 8
		DEFAULT => -43
	},
	{#State 9
		ACTIONS => {
			'AND' => 35,
			'AMP' => 36,
			'AMP_AMP' => 37
		},
		DEFAULT => -2
	},
	{#State 10
		ACTIONS => {
			'EQUALS' => 38,
			'BANG_EQUALS' => 40,
			'EQUALS_EQUALS' => 39
		},
		DEFAULT => -5
	},
	{#State 11
		ACTIONS => {
			'AXIS_NAME' => 6,
			'STAR' => -45,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'PI' => -45,
			'TEXT' => -45,
			'COMMENT' => -45,
			'NAME_COLON_STAR' => -45,
			'QNAME' => -45,
			'AT' => 24,
			'NODE' => -45
		},
		DEFAULT => -36,
		GOTOS => {
			'relative_location_path' => 41,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 12
		ACTIONS => {
			'PLUS' => 42,
			'MINUS' => 43
		},
		DEFAULT => -13
	},
	{#State 13
		DEFAULT => -29
	},
	{#State 14
		ACTIONS => {
			'LPAR' => 44
		}
	},
	{#State 15
		DEFAULT => -39
	},
	{#State 16
		ACTIONS => {
			'LT' => 47,
			'GT' => 45,
			'LTE' => 48,
			'GTE' => 46
		},
		DEFAULT => -9
	},
	{#State 17
		DEFAULT => -54
	},
	{#State 18
		ACTIONS => {
			'MULTIPLY' => 49,
			'MOD' => 50,
			'DIV' => 51
		},
		DEFAULT => -18
	},
	{#State 19
		ACTIONS => {
			'VBAR_VBAR' => 52,
			'OR' => 53
		},
		DEFAULT => -1
	},
	{#State 20
		DEFAULT => -52
	},
	{#State 21
		ACTIONS => {
			'AXIS_NAME' => 6,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'AT' => 24
		},
		DEFAULT => -45,
		GOTOS => {
			'relative_location_path' => 54,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 22
		DEFAULT => -21
	},
	{#State 23
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'function_call' => 17,
			'unary_expr' => 55,
			'path_expr' => 26,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 24
		DEFAULT => -47
	},
	{#State 25
		ACTIONS => {
			'' => 56
		}
	},
	{#State 26
		DEFAULT => -27
	},
	{#State 27
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'and_expr' => 9,
			'equality_expr' => 10,
			'additive_expr' => 12,
			'location_path' => 13,
			'step' => 15,
			'relational_expr' => 16,
			'function_call' => 17,
			'multiplicative_expr' => 18,
			'or_expr' => 19,
			'unary_expr' => 22,
			'path_expr' => 26,
			'expr' => 57,
			'absolute_location_path' => 29,
			'axis' => 28
		}
	},
	{#State 28
		ACTIONS => {
			'QNAME' => 63,
			'NODE' => 64,
			'COMMENT' => 61,
			'PI' => 60,
			'TEXT' => 59,
			'STAR' => 58,
			'NAME_COLON_STAR' => 62
		},
		GOTOS => {
			'node' => 65
		}
	},
	{#State 29
		DEFAULT => -35
	},
	{#State 30
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'relative_location_path' => 3,
			'path_expr' => 66,
			'primary_expr' => 4,
			'function_call' => 17,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 31
		ACTIONS => {
			'AXIS_NAME' => 6,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'AT' => 24
		},
		DEFAULT => -45,
		GOTOS => {
			'axis' => 28,
			'step' => 67
		}
	},
	{#State 32
		ACTIONS => {
			'AXIS_NAME' => 6,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'AT' => 24
		},
		DEFAULT => -45,
		GOTOS => {
			'axis' => 28,
			'step' => 68
		}
	},
	{#State 33
		ACTIONS => {
			'SLASH' => 69,
			'SLASH_SLASH' => 71,
			'LSQB' => 72
		},
		DEFAULT => -31,
		GOTOS => {
			'segment' => 70
		}
	},
	{#State 34
		DEFAULT => -46
	},
	{#State 35
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'relational_expr' => 16,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'unary_expr' => 22,
			'equality_expr' => 73,
			'path_expr' => 26,
			'additive_expr' => 12,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 36
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'relational_expr' => 16,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'unary_expr' => 22,
			'equality_expr' => 74,
			'path_expr' => 26,
			'additive_expr' => 12,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 37
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'relational_expr' => 16,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'unary_expr' => 22,
			'equality_expr' => 75,
			'path_expr' => 26,
			'additive_expr' => 12,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 38
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'relational_expr' => 76,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'unary_expr' => 22,
			'path_expr' => 26,
			'additive_expr' => 12,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 39
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'relational_expr' => 77,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'unary_expr' => 22,
			'path_expr' => 26,
			'additive_expr' => 12,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 40
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'relational_expr' => 78,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'unary_expr' => 22,
			'path_expr' => 26,
			'additive_expr' => 12,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 41
		ACTIONS => {
			'SLASH' => 31,
			'SLASH_SLASH' => 32
		},
		DEFAULT => -37
	},
	{#State 42
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'multiplicative_expr' => 79,
			'function_call' => 17,
			'unary_expr' => 22,
			'path_expr' => 26,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 43
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'multiplicative_expr' => 80,
			'function_call' => 17,
			'unary_expr' => 22,
			'path_expr' => 26,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 44
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'RPAR' => -56,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'and_expr' => 9,
			'args' => 81,
			'equality_expr' => 10,
			'additive_expr' => 12,
			'location_path' => 13,
			'step' => 15,
			'opt_args' => 82,
			'relational_expr' => 16,
			'function_call' => 17,
			'multiplicative_expr' => 18,
			'or_expr' => 19,
			'unary_expr' => 22,
			'expr' => 83,
			'path_expr' => 26,
			'absolute_location_path' => 29,
			'axis' => 28
		}
	},
	{#State 45
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'unary_expr' => 22,
			'additive_expr' => 84,
			'path_expr' => 26,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 46
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'unary_expr' => 22,
			'additive_expr' => 85,
			'path_expr' => 26,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 47
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'unary_expr' => 22,
			'additive_expr' => 86,
			'path_expr' => 26,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 48
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'unary_expr' => 22,
			'additive_expr' => 87,
			'path_expr' => 26,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 49
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'function_call' => 17,
			'unary_expr' => 88,
			'path_expr' => 26,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 50
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'function_call' => 17,
			'unary_expr' => 89,
			'path_expr' => 26,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 51
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'function_call' => 17,
			'unary_expr' => 90,
			'path_expr' => 26,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 52
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'relational_expr' => 16,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'and_expr' => 91,
			'unary_expr' => 22,
			'equality_expr' => 10,
			'path_expr' => 26,
			'additive_expr' => 12,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 53
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'relational_expr' => 16,
			'primary_expr' => 4,
			'multiplicative_expr' => 18,
			'function_call' => 17,
			'and_expr' => 92,
			'unary_expr' => 22,
			'equality_expr' => 10,
			'path_expr' => 26,
			'additive_expr' => 12,
			'location_path' => 13,
			'absolute_location_path' => 29,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 54
		ACTIONS => {
			'SLASH' => 31,
			'SLASH_SLASH' => 32
		},
		DEFAULT => -38
	},
	{#State 55
		DEFAULT => -26
	},
	{#State 56
		DEFAULT => -0
	},
	{#State 57
		ACTIONS => {
			'RPAR' => 93
		}
	},
	{#State 58
		DEFAULT => -61
	},
	{#State 59
		ACTIONS => {
			'LPAR' => 94
		}
	},
	{#State 60
		ACTIONS => {
			'LPAR' => 95
		}
	},
	{#State 61
		ACTIONS => {
			'LPAR' => 96
		}
	},
	{#State 62
		DEFAULT => -62
	},
	{#State 63
		DEFAULT => -60
	},
	{#State 64
		ACTIONS => {
			'LPAR' => 97
		}
	},
	{#State 65
		DEFAULT => -48,
		GOTOS => {
			'predicates' => 98
		}
	},
	{#State 66
		DEFAULT => -28
	},
	{#State 67
		DEFAULT => -40
	},
	{#State 68
		DEFAULT => -41
	},
	{#State 69
		ACTIONS => {
			'AXIS_NAME' => 6,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'AT' => 24
		},
		DEFAULT => -45,
		GOTOS => {
			'relative_location_path' => 99,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 70
		DEFAULT => -30
	},
	{#State 71
		ACTIONS => {
			'AXIS_NAME' => 6,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'AT' => 24
		},
		DEFAULT => -45,
		GOTOS => {
			'relative_location_path' => 100,
			'axis' => 28,
			'step' => 15
		}
	},
	{#State 72
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'and_expr' => 9,
			'equality_expr' => 10,
			'additive_expr' => 12,
			'location_path' => 13,
			'step' => 15,
			'relational_expr' => 16,
			'function_call' => 17,
			'multiplicative_expr' => 18,
			'or_expr' => 19,
			'unary_expr' => 22,
			'path_expr' => 26,
			'expr' => 101,
			'absolute_location_path' => 29,
			'axis' => 28
		}
	},
	{#State 73
		ACTIONS => {
			'EQUALS' => 38,
			'BANG_EQUALS' => 40,
			'EQUALS_EQUALS' => 39
		},
		DEFAULT => -6
	},
	{#State 74
		ACTIONS => {
			'EQUALS' => 38,
			'BANG_EQUALS' => 40,
			'EQUALS_EQUALS' => 39
		},
		DEFAULT => -8
	},
	{#State 75
		ACTIONS => {
			'EQUALS' => 38,
			'BANG_EQUALS' => 40,
			'EQUALS_EQUALS' => 39
		},
		DEFAULT => -7
	},
	{#State 76
		ACTIONS => {
			'LT' => 47,
			'GT' => 45,
			'LTE' => 48,
			'GTE' => 46
		},
		DEFAULT => -10
	},
	{#State 77
		ACTIONS => {
			'LT' => 47,
			'GT' => 45,
			'LTE' => 48,
			'GTE' => 46
		},
		DEFAULT => -12
	},
	{#State 78
		ACTIONS => {
			'LT' => 47,
			'GT' => 45,
			'LTE' => 48,
			'GTE' => 46
		},
		DEFAULT => -11
	},
	{#State 79
		ACTIONS => {
			'MULTIPLY' => 49,
			'MOD' => 50,
			'DIV' => 51
		},
		DEFAULT => -19
	},
	{#State 80
		ACTIONS => {
			'MULTIPLY' => 49,
			'MOD' => 50,
			'DIV' => 51
		},
		DEFAULT => -20
	},
	{#State 81
		ACTIONS => {
			'COMMA' => 102
		},
		DEFAULT => -57
	},
	{#State 82
		ACTIONS => {
			'RPAR' => 103
		}
	},
	{#State 83
		DEFAULT => -58
	},
	{#State 84
		ACTIONS => {
			'PLUS' => 42,
			'MINUS' => 43
		},
		DEFAULT => -15
	},
	{#State 85
		ACTIONS => {
			'PLUS' => 42,
			'MINUS' => 43
		},
		DEFAULT => -17
	},
	{#State 86
		ACTIONS => {
			'PLUS' => 42,
			'MINUS' => 43
		},
		DEFAULT => -14
	},
	{#State 87
		ACTIONS => {
			'PLUS' => 42,
			'MINUS' => 43
		},
		DEFAULT => -16
	},
	{#State 88
		DEFAULT => -22
	},
	{#State 89
		DEFAULT => -24
	},
	{#State 90
		DEFAULT => -23
	},
	{#State 91
		ACTIONS => {
			'AND' => 35,
			'AMP' => 36,
			'AMP_AMP' => 37
		},
		DEFAULT => -4
	},
	{#State 92
		ACTIONS => {
			'AND' => 35,
			'AMP' => 36,
			'AMP_AMP' => 37
		},
		DEFAULT => -3
	},
	{#State 93
		DEFAULT => -51
	},
	{#State 94
		ACTIONS => {
			'RPAR' => 104
		}
	},
	{#State 95
		ACTIONS => {
			'LITERAL' => 105
		},
		DEFAULT => -67,
		GOTOS => {
			'opt_literal' => 106
		}
	},
	{#State 96
		ACTIONS => {
			'RPAR' => 107
		}
	},
	{#State 97
		ACTIONS => {
			'RPAR' => 108
		}
	},
	{#State 98
		ACTIONS => {
			'LSQB' => 72
		},
		DEFAULT => -42
	},
	{#State 99
		ACTIONS => {
			'SLASH' => 31,
			'SLASH_SLASH' => 32
		},
		DEFAULT => -32
	},
	{#State 100
		ACTIONS => {
			'SLASH' => 31,
			'SLASH_SLASH' => 32
		},
		DEFAULT => -33
	},
	{#State 101
		ACTIONS => {
			'RSQB' => 109
		}
	},
	{#State 102
		ACTIONS => {
			'NUMBER' => 2,
			'AXIS_NAME' => 6,
			'DOLLAR_QNAME' => 5,
			'DOT' => 8,
			'DOT_DOT' => 7,
			'SLASH' => 11,
			'FUNCTION_NAME' => 14,
			'LITERAL' => 20,
			'SLASH_SLASH' => 21,
			'MINUS' => 23,
			'AT' => 24,
			'LPAR' => 27
		},
		DEFAULT => -45,
		GOTOS => {
			'union_expr' => 1,
			'relative_location_path' => 3,
			'primary_expr' => 4,
			'and_expr' => 9,
			'equality_expr' => 10,
			'additive_expr' => 12,
			'location_path' => 13,
			'step' => 15,
			'relational_expr' => 16,
			'function_call' => 17,
			'multiplicative_expr' => 18,
			'or_expr' => 19,
			'unary_expr' => 22,
			'path_expr' => 26,
			'expr' => 110,
			'absolute_location_path' => 29,
			'axis' => 28
		}
	},
	{#State 103
		DEFAULT => -55
	},
	{#State 104
		DEFAULT => -65
	},
	{#State 105
		DEFAULT => -68
	},
	{#State 106
		ACTIONS => {
			'RPAR' => 111
		}
	},
	{#State 107
		DEFAULT => -64
	},
	{#State 108
		DEFAULT => -66
	},
	{#State 109
		DEFAULT => -49
	},
	{#State 110
		DEFAULT => -59
	},
	{#State 111
		DEFAULT => -63
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'expr', 1, undef
	],
	[#Rule 2
		 'or_expr', 1, undef
	],
	[#Rule 3
		 'or_expr', 3,
sub
#line 58 "XPath.yp"
{
      die "XPath expression 'or' not supported\n";
    }
	],
	[#Rule 4
		 'or_expr', 3,
sub
#line 61 "XPath.yp"
{
        die "XPath uses 'or' instead of Perl's '||'\n";
    }
	],
	[#Rule 5
		 'and_expr', 1, undef
	],
	[#Rule 6
		 'and_expr', 3,
sub
#line 68 "XPath.yp"
{
      my ($expr);
      $expr = (ref $_[1] eq 'ARRAY')? $_[1] : [$_[1]];
      push @{$expr}, $_[3];
      return $expr;
    }
	],
	[#Rule 7
		 'and_expr', 3,
sub
#line 74 "XPath.yp"
{
        die "XPath uses 'and' instead of Perl's '&&'\n";
    }
	],
	[#Rule 8
		 'and_expr', 3,
sub
#line 77 "XPath.yp"
{
        die "XPath uses 'and' instead of Perl's '&'\n";
    }
	],
	[#Rule 9
		 'equality_expr', 1, undef
	],
	[#Rule 10
		 'equality_expr', 3,
sub
#line 84 "XPath.yp"
{
      my ($expr);
      $expr = ((ref $_[1] eq 'CODE')?
	       $_[1]->($_[0], undef, undef, $_[3]) :
	       $_[1]);
    SWITCH:{
	UNIVERSAL::isa($expr, 'XML::Object::XPath::Node') && do {
	  $expr->value($_[3]);
	  last SWITCH;
	};
	UNIVERSAL::isa($expr, 'XML::Object::XPath::Function') && do {
	  $expr->value($_[3]);
	  last SWITCH;
	}
      }
      return $expr;
    }
	],
	[#Rule 11
		 'equality_expr', 3,
sub
#line 101 "XPath.yp"
{
      die "XPath expression != not supported\n";
    }
	],
	[#Rule 12
		 'equality_expr', 3,
sub
#line 104 "XPath.yp"
{
      die "XPath uses '=' instead of Perl's '=='\n";
    }
	],
	[#Rule 13
		 'relational_expr', 1, undef
	],
	[#Rule 14
		 'relational_expr', 3,
sub
#line 111 "XPath.yp"
{ 
      die "XPath expression '<' not supported\n";
    }
	],
	[#Rule 15
		 'relational_expr', 3,
sub
#line 114 "XPath.yp"
{
      die "XPath expression '>' not supported\n";
    }
	],
	[#Rule 16
		 'relational_expr', 3,
sub
#line 117 "XPath.yp"
{
      die "XPath expression '<=' not supported\n";
    }
	],
	[#Rule 17
		 'relational_expr', 3,
sub
#line 120 "XPath.yp"
{
      die "XPath expression '>=' not supported\n";
    }
	],
	[#Rule 18
		 'additive_expr', 1, undef
	],
	[#Rule 19
		 'additive_expr', 3,
sub
#line 127 "XPath.yp"
{
      die "XPath expression '+' not supported\n";
    }
	],
	[#Rule 20
		 'additive_expr', 3,
sub
#line 130 "XPath.yp"
{
      die "XPath expression '-' not supported\n";
    }
	],
	[#Rule 21
		 'multiplicative_expr', 1, undef
	],
	[#Rule 22
		 'multiplicative_expr', 3,
sub
#line 137 "XPath.yp"
{
      die "XPath expression '*' not supported\n";
    }
	],
	[#Rule 23
		 'multiplicative_expr', 3,
sub
#line 140 "XPath.yp"
{
      die "XPath expression 'div' not supported\n";
    }
	],
	[#Rule 24
		 'multiplicative_expr', 3,
sub
#line 143 "XPath.yp"
{
      die "XPath expression 'mod' not supported\n";
    }
	],
	[#Rule 25
		 'unary_expr', 1, undef
	],
	[#Rule 26
		 'unary_expr', 2,
sub
#line 150 "XPath.yp"
{
      die "XPath expression '-' not supported\n";
    }
	],
	[#Rule 27
		 'union_expr', 1, undef
	],
	[#Rule 28
		 'union_expr', 3,
sub
#line 157 "XPath.yp"
{
      die "XPath expression '|' not supported\n";
    }
	],
	[#Rule 29
		 'path_expr', 1, undef
	],
	[#Rule 30
		 'path_expr', 3,
sub
#line 164 "XPath.yp"
{
        if ( defined $_[2] ) {
            die "This XPath implementation has no node sets, (expression)[predicate] is not supported\n";
        }
        if ( defined $_[3] ) {
            die "This XPath implementation has no node sets, (expression)/path is not supported\n";
        }
        $_[1];
    }
	],
	[#Rule 31
		 'segment', 0, undef
	],
	[#Rule 32
		 'segment', 2, undef
	],
	[#Rule 33
		 'segment', 2, undef
	],
	[#Rule 34
		 'location_path', 1, undef
	],
	[#Rule 35
		 'location_path', 1, undef
	],
	[#Rule 36
		 'absolute_location_path', 1,
sub
#line 187 "XPath.yp"
{}
	],
	[#Rule 37
		 'absolute_location_path', 2,
sub
#line 188 "XPath.yp"
{
      my ($document, $path);
      $document = $_[0]->{USER}->{Driver}->document($_[1]);
      $path = (ref $_[2] eq 'CODE')? $_[2]->($_[0]) : $_[2];
      $document->chain($path);
      $document;
    }
	],
	[#Rule 38
		 'absolute_location_path', 2,
sub
#line 195 "XPath.yp"
{
      die "Only absolute paths are supported\n";
    }
	],
	[#Rule 39
		 'relative_location_path', 1, undef
	],
	[#Rule 40
		 'relative_location_path', 3,
sub
#line 203 "XPath.yp"
{
      my ($path);
      $path = (ref $_[1] eq 'CODE')? $_[1]->($_[0]) : $_[1];
      return (ref $_[3] eq 'CODE')?
	$_[3]->($_[0], $path, $_[2]) : $path;
    }
	],
	[#Rule 41
		 'relative_location_path', 3,
sub
#line 209 "XPath.yp"
{
      die "Only absolute paths are supported\n";
    }
	],
	[#Rule 42
		 'step', 3,
sub
#line 215 "XPath.yp"
{
      my ($node, $axis, $qname, $predicates);
      ($axis, $qname, $predicates) = @_[1..3];
      return undef unless defined $qname;
      if(ref $axis eq 'CODE') {
	return $axis->(@_);
      }
      $node = $_[0]->{USER}->{Driver}->element($qname, $predicates);
      return sub {
	($_[1])? do { $_[1]->chain($node); $_[1] } : $node;
      };
    }
	],
	[#Rule 43
		 'step', 1,
sub
#line 227 "XPath.yp"
{
      return sub { $_[1] }
    }
	],
	[#Rule 44
		 'step', 1,
sub
#line 230 "XPath.yp"
{
      return sub {
	($_[1])? $_[1]->unchain : die "No parent node supplied\n";
	return $_[1];
      };
    }
	],
	[#Rule 45
		 'axis', 0,
sub
#line 239 "XPath.yp"
{  }
	],
	[#Rule 46
		 'axis', 2,
sub
#line 240 "XPath.yp"
{
      my ($name);
      $name = $_[1];
    SWITCH: {
	($name eq 'child') && do {
	  return undef;
	};
	($name eq 'attribute') && do {
	  return sub {
	    my ($attribute);
	    $attribute = $_[0]->{USER}->{Driver}->attribute($_[2], $_[3]);
	    return sub {
	      ($_[1])? do { $_[1]->chain($attribute); $_[1] } : $attribute;
	    };
	  };
	};
	($name eq 'self') && do {
	  return sub { sub { $_[1] } };
	};
	($name eq 'parent') && do {
	  return sub {
	    return sub {
	      ($_[1])? $_[1]->unchain : die "No parent node supplied\n";
	      return $_[1];
	    };
	  };
	};
      };
      die "Xpath ${name}:: axis not supported\n";
    }
	],
	[#Rule 47
		 'axis', 1,
sub
#line 270 "XPath.yp"
{
      return sub {
	my ($attribute);
	$attribute = $_[0]->{USER}->{Driver}->attribute($_[2],$_[3]);
	return sub {
	  ($_[1])? do { $_[1]->chain($attribute); $_[1] } : $attribute;
	};
      };
    }
	],
	[#Rule 48
		 'predicates', 0, undef
	],
	[#Rule 49
		 'predicates', 4,
sub
#line 283 "XPath.yp"
{
      my ($predicates);
      $predicates = $_[1]? $_[1] : [];
      push @{$predicates},
	((ref $_[3] eq 'ARRAY')? @{$_[3]} : $_[3]);
      return $predicates;
    }
	],
	[#Rule 50
		 'primary_expr', 1,
sub
#line 293 "XPath.yp"
{
      die "XPath parameters not supported\n";
    }
	],
	[#Rule 51
		 'primary_expr', 3, undef
	],
	[#Rule 52
		 'primary_expr', 1,
sub
#line 297 "XPath.yp"
{
      my ($literal);
      $literal = ${$_[1]};
      $literal =~ s/^[\'\"](.*)[\'\"]$/$1/;
      return $literal;
    }
	],
	[#Rule 53
		 'primary_expr', 1,
sub
#line 303 "XPath.yp"
{
      return ${$_[1]};
    }
	],
	[#Rule 54
		 'primary_expr', 1, undef
	],
	[#Rule 55
		 'function_call', 4,
sub
#line 310 "XPath.yp"
{
      return $_[0]->{USER}->{Driver}->function($_[1], $_[3]);
    }
	],
	[#Rule 56
		 'opt_args', 0,
sub
#line 316 "XPath.yp"
{  }
	],
	[#Rule 57
		 'opt_args', 1, undef
	],
	[#Rule 58
		 'args', 1,
sub
#line 321 "XPath.yp"
{
        [ $_[1] ];
    }
	],
	[#Rule 59
		 'args', 3,
sub
#line 324 "XPath.yp"
{
      push @{$_[1]}, $_[3];
      $_[1];
    }
	],
	[#Rule 60
		 'node', 1,
sub
#line 331 "XPath.yp"
{  $_[1]  }
	],
	[#Rule 61
		 'node', 1,
sub
#line 332 "XPath.yp"
{
      die "Multiple node references not supported\n";
    }
	],
	[#Rule 62
		 'node', 1,
sub
#line 335 "XPath.yp"
{
      die "Multiple node references not supported\n";
    }
	],
	[#Rule 63
		 'node', 4,
sub
#line 338 "XPath.yp"
{
      die "XPath pi() node not supported\n";
    }
	],
	[#Rule 64
		 'node', 3,
sub
#line 341 "XPath.yp"
{
      die "XPath comment() node not supported\n";
    }
	],
	[#Rule 65
		 'node', 3,
sub
#line 344 "XPath.yp"
{ }
	],
	[#Rule 66
		 'node', 3,
sub
#line 345 "XPath.yp"
{ '' }
	],
	[#Rule 67
		 'opt_literal', 0, undef
	],
	[#Rule 68
		 'opt_literal', 1,
sub
#line 350 "XPath.yp"
{ }
	]
],
                                  @_);
    bless($self,$class);
}

#line 353 "XPath.yp"


my %tokens = (qw(
    .           DOT
    ..          DOT_DOT
    @           AT
    *           STAR
    (           LPAR
    )           RPAR
    [           LSQB
    ]           RSQB
    ::          COLON_COLON
    /           SLASH
    //          SLASH_SLASH
    |           VBAR
    +           PLUS
    -           MINUS
    =           EQUALS
    !=          BANG_EQUALS
    >           GT
    <           LT
    >=          GTE
    <=          LTE

    ==          EQUALS_EQUALS
    ||          VBAR_VBAR
    &&          AMP_AMP
    &           AMP
),
    "," =>      "COMMA"
);

my $simple_tokens =
    join "|",
        map
            quotemeta,
            reverse
                sort {
                    length $a <=> length $b
                } keys %tokens;

my $NCName = "(?:[a-zA-Z_][a-zA-Z0-9_.-]*)"; ## TODO: comb. chars & Extenders

my %NodeType = qw(
    node                   NODE
    text                   TEXT
    comment                COMMENT
    processing-instruction PI
);

my $NodeType = "(?:" .
    join( "|", map quotemeta, sort {length $a <=> length $b} keys %NodeType ) .
    ")";

my $AxisName = "(?:" .  join( "|", split /\n/, <<AXIS_LIST_END ) . ")" ;
ancestor
ancestor-or-self
attribute
child
descendant
descendant-or-self
following
following-sibling
namespace
parent
preceding
preceding-sibling
self
AXIS_LIST_END

my %preceding_tokens = map { ( $_ => undef ) } ( qw(
    @ :: [
    and or mod div
    *
    / // | + - = != < <= > >=

    == & && ||
    ),
    "(", ","
) ;

sub debugging () { 0}

sub lex {
    my ( $p ) = @_;
    my $d = $p->{USER};
    my $input = \$d->{Input};

    ## This needs to be more contextual, only recognizing axis/function-name
    if ( ( pos( $$input ) || 0 ) == length $$input ) {
        $d->{LastToken} = undef;
        return ( '', undef );
    }

    my ( $token, $val ) ;
    ## First do the disambiguation rules:

    ## If there is a preceding token and the preceding token is not
    ## one of "@", "::", "(", "[", "," or an Operator,
    if ( defined $d->{LastToken}
        && ! exists $preceding_tokens{$d->{LastToken}}
    ) {
        ## a * must be recognized as a MultiplyOperator
        if ( $$input =~ /\G\s*\*/gc ) {
            ( $token, $val ) = ( MULTIPLY => "*" );
        }
        ## an NCName must be recognized as an OperatorName.
        elsif ( $$input =~ /\G\s*($NCName)/gc ) {
            die "Expected and, or, mod or div, got '$1'"
                unless 0 <= index "and|or|mod|div", $1;
            ( $token, $val ) = ( uc $1, $1 );
        }
    }

    ## NOTE: \s is only an approximation for ExprWhitespace
    unless ( defined $token ) {
        $$input =~ m{\G\s*(?:
            ## If the character following an NCName (possibly after
            ## intervening ExprWhitespace) is (, then the token must be
            ## recognized as a NodeType or a FunctionName.

            ($NCName)\s*(?=\()

            ## If the two characters following an NCName (possibly after
            ## intervening ExprWhitespace) are ::, then the token must be
            ## recognized as an AxisName

            |($NCName)\s*(?=::)

            |($NCName:\*)                           #NAME_COLON_STAR
            |((?:$NCName:)?$NCName)                 #QNAME
            |('[^']*'|"[^"]*")                      #LITERAL
            |(-?\d+(?:\.\d+)?|\.\d+)                #NUMBER
            |\$((?:$NCName:)?$NCName)               #DOLLAR_QNAME
            |($simple_tokens)
        )\s*}gcx;

        ( $token, $val ) =
            defined $1  ? (
                exists $NodeType{$1}
                    ? ( $NodeType{$1}, $1 )
                    : ( FUNCTION_NAME => $1 )
            ) :
            defined $2  ? (
                0 <= index( $AxisName, $2 )
                    ? ( AXIS_NAME => $2 )
                    : die "Expected an Axis Name, got '$2' at ",
                        pos $p->{USER}->{Input},
                        "\n"
            ) :
            defined  $3 ? ( NAME_COLON_STAR  =>  $3 ) :
            defined  $4 ? ( QNAME            =>  $4 ) :
            defined  $5 ? ( LITERAL          =>  do {
                    my $s = substr( $5, 1, -1 );
                    $s =~ s/([\\'])/\\$1/g;
                    bless \"'$s'", "string constant";
                }
            ) :
            defined  $6 ? ( NUMBER           =>  bless \"$6", "number constant" ) :
            defined  $7 ? ( DOLLAR_QNAME     =>  $7 ) :
            defined  $8 ? ( $tokens{$8}      =>  $8 ) :
            die "Failed to parse '$$input' at ",
                pos $$input,
                "\n";

        ## the parser needs to know whether an path expression is being
        ## parsed in a predicate or not so it can deal with paths
        ## using immediate code in predicates instead of converting them
        ## to incremental code run as precursors.
    #    if ( $p->{USER}->{ExitedPredicate} ) {
    #        --$XFD::predicate_depth;
    #    }
         $p->{USER}->{ExitedPredicate} = $token eq "RSQB";

#        if ( $token eq "LSQB" ) {
#            ++$XFD::predicate_depth;
 #       }
    }

    $d->{LastToken} = $val;

    if ( debugging ) {
        warn
            "'",
            $$input,
            "' (",
            pos $$input,
            "):",
            join( " => ", map defined $_ ? $_ : "<undef>", $token, $val ),
            "\n";
    }

    return ( $token, $val );
}

sub error {
  my ( $p ) = @_;
  warn("Couldn't parse '$p->{USER}->{Input}' at position ",
       pos $p->{USER}->{Input}, "\n");
}

sub compile {
  my ($self, $driver, $xpath) = @_;
  my ($parser, $result);
  $parser = XML::Object::XPath->new(yylex   => \&lex,
				    yyerror => \&error);

  $parser->{USER}->{Driver} = $driver;
  #$parser->{USER}->{ExitedPredicate} = 0;
  $parser->{USER}->{Input} = $xpath;
  return $parser->YYParse;
}

package XML::Object::XPath::Node;

sub new {
  die "Abstract class\n";
}

package XML::Object::XPath::Function;

sub new {
  die "Abstract class\n";
}

1;

1;
