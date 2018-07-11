%lex
%options case-insensitive
%%

\[([^\]])*?\]									return 'BRALITERAL'
(["](\\.|[^"]|\\\")*?["])+		return 'STRING'
([`](\\.|[^"]|\\\")*?[`])+		return 'BRALITERAL'
(['](\\.|[^']|\\\')*?['])+		return 'STRING'

\$[a-zA-Z_][a-zA-Z_0-9]*			return 'VARNAME'


"--"(.*?)($|\r\n|\r|\n)				/* skip -- comments */

\s+   												/* skip whitespace */

'AND'				return 'AND'
'ANY'				return 'ANY'
'AS'				return 'AS'
'ASC'				return 'ASC'
'BETWEEN'		return 'BETWEEN'
'BY'				return 'BY'
'CASE'			return 'CASE'
'COLLATE'		return 'COLLATE'
'CROSS'			return 'CROSS'
'DESC'			return 'DESC'
'DISTINCT'	return 'DISTINCT'
'ELSE'			return 'ELSE'
'END'				return 'END'
'EVERY'			return 'EVERY'
'EXISTS'		return 'EXISTS'
'FROM'			return 'FROM'
'GROUP'			return 'GROUP'
'HAVING'		return 'HAVING'
'IN'				return 'IN'
'INNER'			return 'INNER'
'IS'				return 'IS'
'ISNULL'		return 'ISNULL'
'JOIN'			return 'JOIN'
'LEFT'			return 'LEFT'
'LIKE'			return 'LIKE'
'LIMIT'			return 'LIMIT'
'MATCH'			return 'MATCH'
'MISSING'		return 'MISSING'
'NATURAL'		return 'NATURAL'
'NOT'				return 'NOT'
'NOTNULL'		return 'NOTNULL'
'NULL'			return 'NULL'
'OFFSET'		return 'OFFSET'
'ON'				return 'ON'
'OR'				return 'OR'
'ORDER'			return 'ORDER'
'OUTER'			return 'OUTER'
'SATISFIES'	return 'SATISFIES'
'SELECT'		return 'SELECT'
'THEN'			return 'THEN'
'WHEN'			return 'WHEN'
'WHERE'			return 'WHERE'

[-]?(\d*[.])?\d+[eE]\d+							return 'NUMBER'
[-]?(\d*[.])?\d+								return 'NUMBER'

'+'												return 'PLUS'
'-' 											return 'MINUS'
'*'												return 'STAR'
'/'												return 'SLASH'
'%'												return 'REM'
'<>'											return 'NE'
'!='											return 'NE'
'>='											return 'GE'
'>'												return 'GT'
'<='											return 'LE'
'<'												return 'LT'
'='												return 'EQ'

'('												return 'LPAR'
')'												return 'RPAR'


'.'												return 'DOT'
','												return 'COMMA'
':'												return 'COLON'
';'												return 'SEMICOLON'
'?'												return 'QUESTION'

[a-zA-Z_][a-zA-Z_0-9]*                       	return 'LITERAL'

<<EOF>>               							return 'EOF'
.												return 'INVALID'

/lex

/* %left unary_operator binary_operator  */

%left OR
%left BETWEEN
%left AND
%right NOT
%left IS MATCH LIKE IN ISNULL NOTNULL NE EQ
%left GT LE LT GE
$left PLUS MINUS
%left STAR SLASH REM
%left CONCAT
%left COLLATE
%right BITNOT

%start main

%%

name
	: LITERAL
		{ $$ = $1; }
	| BRALITERAL
		{ $$ = $1.substr(1,$1.length-2); }
	;

varname
	: VARNAME
		{ $$ = $1; }
	;

signed_number
	: NUMBER
		{ $$ = parseFloat($1); }
	;

string_literal
	: STRING
		{ $$ = $1.substr(1,$1.length-2); }
	| XSTRING
		{ $$ = $1.substr(1,$1.length-2); }
	;

database_table_name
	: name DOT name
		{ $$ = {database:$1, table:$3}; }
	| name
		{ $$ = {table:$1}; }
	;

main
	: sql_stmt EOF
		{
			$$ = $1;
			return $$;
		}
	;

sql_stmt_list
	: sql_stmt_list SEMICOLON sql_stmt
		{ $$ = $1; if($3) $$.push($3); }
	| sql_stmt
		{ $$ = [$1]; }
	;

sql_stmt
	: sql_stmt_explain sql_stmt_stmt
		{ $$ = $2; yy.extend($$, $1); }
	|
		{ $$ = undefined; }
	;

sql_stmt
	: select_stmt
	;

database
	:
	| DATABASE
	;

if_not_exists
	:
		{ $$ = undefined; }
	| IF NOT EXISTS
		{ $$ = {if_not_exists: true}; }
	;

columns
	: columns COMMA name
		{ $$ = $1; $$.push($3); }
	| name
		{ $$ = [$1]; }
	;

where
	:
	| WHERE expr
		{ $$ = $2; }
	;

when
	: WHEN expr
		{ $$ = {when: $2}; }
	|
	;

type_name
	: names
		{ $$ = {type: $1.toUpperCase()}; }
	| names LPAR signed_number RPAR
		{ $$ = {type: $1.toUpperCase(), precision: $3}; }
	| names LPAR signed_number COMMA signed_number RPAR
		{ $$ = {type: $1.toUpperCase(), precision: $3, scale:$5}; }
	;

names
	: names name
		{ $$ = $1+' '+$2; }
	| name
		{ $$ =$1; }
	;

asc_desc
	:
		{ $$ = undefined; }
	| ASC
		{ $$ = 'ASC'; }
	| DESC
		{ $$ = 'DESC'; }
	;

limit_clause
	:
		{ $$ = undefined; }
	| ORDER BY ordering_terms
		{
			$$ = { ORDER_BY: $3 };
		}
	| LIMIT signed_number
		{
			$$ = { LIMIT: $2 };
		}
	| LIMIT signed_number OFFSET signed_number
		{
			$$ = { LIMIT: $2, OFFSET: $4 };
		}
	| ORDER BY ordering_terms LIMIT signed_number
		{
			$$ = { ORDER_BY: $3, LIMIT: $5 };
		}
	| ORDER BY ordering_terms LIMIT signed_number OFFSET signed_number
		{
			$$ = { ORDER_BY: $3, LIMIT: $5, OFFSET: $7 };
		}
	;

ordering_terms
	: ordering_terms COMMA ordering_term
		{ $$ = $1; $$.push($3); }
	| ordering_term
		{ $$ = [$1]; }
	;

ordering_term
	: name asc_desc
		{
			if ($2 == 'DESC') {
				$$ = ['DESC', ['.', $1]];
			} else {
				$$ = ['.', $1];
			}
		}
	;

select_stmt
	: compound_selects limit_clause
		{
			$$ = ['SELECT', $1];
			yy.extend($1, $2);
		}
	;

compound_selects
	: compound_selects compound_operator select
		{ $$ = $1; yy.extend($3,{compound:$2}); $$.push($3); }
	| select
		{ $$ = $1; }
	;

select
	: SELECT distinct result_columns from where group_by
		{
			$$ = { WHAT: $3 };
			if ($2) { $$.DISTINCT = true; }
			if ($4) { $$.FROM = $4; }
			if ($5) { $$.WHERE = $5; }
			if ($6) {
				$$.GROUP_BY = $6.group_by;
				if ($6.having) {
					$$.HAVING = $6.having;
				}
			}
		}
	|
	;

distinct
	:
		{ $$ = undefined; }
	| DISTINCT
		{ $$ = {DISTINCT: true}; }
	;

result_columns
	: result_columns COMMA result_column
		{ $$ = $1; $$.push($3); }
	| result_column
		{ $$ = [$1]; }
	;

result_column
	: STAR
		{ $$ = ['.']; }
	| name DOT STAR
		{ $$ = {table: $1, star:true}; }
	| expr
		{ $$ = $1;  }
	;

alias
	:
		{ $$ = undefined;}
	| name
		{ $$ = {alias: $1};}
	| AS name
		{ $$ = {as: $2};}
	;

from
	:
		{ $$ = undefined; }
	| FROM join_clause
		{ $$ = $2; }
	;

table_or_subquery
	: database_table_name alias
		{ $$ = $1; yy.extend($$,$2); }
	| LPAR join_clause RPAR
		{ $$ = {join:$2}; }
	| LPAR select_stmt RPAR alias
		{ $$ = {select: $2}; yy.extend($2,$4); }
	;

join_clause
	: table_or_subquery
		{ delete $1.table; $$ = [$1]; }
	| join_clause join_operator table_or_subquery join_constraint
		{
			delete $3.table;
			yy.extend($3,$2);
			yy.extend($3,$4);
			$$.push($3);
		}
	;
join_operator
	: COMMA
		{ $$ = {join: 'CROSS'}; }
	| join_type JOIN
		{ $$ = $1; }
	| NATURAL join_type JOIN
		{ $$ = $1; yy.extend($$, {natural:true}); }
	;

join_type
	:
		{ $$ = {join: 'INNER'}; }
	| LEFT OUTER
		{ $$ = {join: 'LEFT'}; }
	| LEFT
		{ $$ = {join: 'LEFT'}; }
	| INNER
		{ $$ = {join: 'INNER'}; }
	| CROSS
		{ $$ = {join: 'CROSS'}; }
	;

join_constraint
	:
		{ $$ = undefined; }
	| ON expr
		{ $$ = {on: $2}; }
	;

group_by
	:
	| GROUP BY exprs
		{ $$ = {group_by: $3}; }
	| GROUP BY exprs HAVING expr
		{ $$ = {group_by: $3, having: $5}; }
	;

exprs
	: exprs COMMA expr
		{ $$ = $1; $$.push($3); }
	| expr
		{ $$ = [$1]; }
	;

values
	: values COMMA value
		{ $$ = $1; $$.push($3); }
	| value
		{ $$ = [$1]; }
	;

value
	: LPAR subvalues RPAR
		{ $$ = $2; }
	;

subvalues
	: subvalues COMMA expr
		{ $$ = $1; $$.push($3); }
	| expr
		{ $$ = [$1]; }
	;

column_expr_list
	: column_expr_list COMMA column_expr
		{ $$ = $1; $$.push($3); }
	| column_expr
		{ $$ = [$1]; }
	;

column_expr
	: name EQ expr
		{ $$ = {column:$1, expr: $3}; }
	;

dot_expr
	: name
		{ $$ = ['.', $1]; }
	| name DOT name
		{ $$ = ['.', $1, $3]; }
	| name DOT dot_expr
		{ $$ = ['.', $1, $3]; }
	;

expr
	: literal_value
		{ $$ = $1; }
	| varname
		{ $$ = ['$', $1.substr(1)]; }
	| NULL
		{ $$ = null; }
	| name
		{ $$ = ['.', $1]; }
	| dot_expr
		{ $$ = $1; }

	| MINUS expr
		{ $$ = ['-', $2]; }

	| expr PLUS expr
		{ $$ = ['+', $1, $3]; }
	| expr MINUS expr
		{ $$ = ['-', $1, $3]; }
	| expr STAR expr
		{ $$ = ['*', $1, $3]; }
	| expr SLASH expr
		{ $$ = ['/', $1, $3]; }
	| expr REM expr
		{ $$ = ['%', $1, $3]; }

	| expr EQ expr
		{ $$ = ['=', $1, $3]; }
	| expr NE expr
		{ $$ = ['!=', $1, $3]; }
	| expr GT expr
		{ $$ = ['>', $1, $3]; }
	| expr GE expr
		{ $$ = ['>=', $1, $3]; }
	| expr LT expr
		{ $$ = ['<', $1, $3]; }
	| expr LE expr
		{ $$ = ['<=', $1, $3]; }


	| expr AND expr
		{ $$ = ['AND', $1, $3]; }
	| expr OR expr
		{ $$ = ['OR', $1, $3]; }
	| NOT expr
		{ $$ = ['NOT', $2]; }


	| name LPAR arguments RPAR
		{ $$ = [$1 + '()', ...$3]; }
	| LPAR expr RPAR
		{ $$ = $2; }

	| expr COLLATE name
		{ $$ = {op: 'COLLATE', left: $1, right:$3};}
	| expr ISNULL
		{ $$ = {op: 'ISNULL', expr:$1}; }
	| expr IS NULL
		{ $$ = ['IS NULL', $1]; }
	| expr NOTNULL
		{ $$ = {op: 'NOTNULL', expr:$1}; }
	| expr NOT NULL
		{ $$ = {op: 'NOTNULL', expr:$1}; }
	| expr IS NOT NULL
		{ $$ = ['IS NOT NULL', $1]; }
	| expr IS MISSING
		{ $$ = ['IS MISSING', $1]; }
	| expr IS NOT MISSING
		{ $$ = ['IS NOT MISSING', $1]; }

	| expr LIKE expr
		{	$$ = ['LIKE', $1, $3]; }
	| expr NOT LIKE expr
		{	$$ = ['NOT', ['LIKE', $1, $4]]; }
	| expr MATCH string_literal
		{
			if ($1[0] != '.' || typeof $1[1] != 'string') throw new Error('Wrong syntax of MATCH');
			$$ = ['MATCH', $1[1], $3];
		}
	| expr NOT MATCH string_literal
		{
			if ($1[0] != '.' || typeof $1[1] != 'string') throw new Error('Wrong syntax of NOT MATCH');
			$$ = ['NOT', ['MATCH', $1[1], $4]];
		}

	| expr BETWEEN expr
		{
			if($3[0] != 'AND') throw new Error('Wrong syntax of BETWEEN AND');
			$$ = ['BETWEEN', $1, $3[1], $3[2]];
		}
	| expr NOT BETWEEN expr
		{
			if($4[0] != 'AND') throw new Error('Wrong syntax of NOT BETWEEN AND');
			$$ = ['NOT', ['BETWEEN', $2, $4[1], $4[2]]];
		}
	| ANY name IN dot_expr SATISFIES expr END
		{ $$ = ['ANY', $2, $4, $6]; }
	| EVERY name IN dot_expr SATISFIES expr END
		{ $$ = ['EVERY', $2, $4, $6]; }
	| ANY AND EVERY name IN dot_expr SATISFIES expr END
		{ $$ = ['EVERY', $4, $6, $8]; }
	| expr IN expr
		{ $$ = ['IN', $1, $3];}
	| expr NOT IN expr
		{ $$ = ['NOT', ['IN', $1, $4]];}
	| CASE expr when_then_list else END
		{ $$ = ["CASE", $2, ...$3, $4]; }
	;

literal_value
	: signed_number
		{ $$ = $1; }
	| string_literal
		{ $$ = $1; }
	;

arguments
	: arguments COMMA expr
		{ $$ = $1; $$.push($3); }
	| expr
		{ $$ = [$1]; }
	;

when_then_list
	: when_then_list when_then
		{ $$ = $1; $$.push($2); }
	| when_then
		{ $$ = [$1]; }
	;

when_then
	: WHEN expr THEN expr
		{ $$ = ["WHEN", $2, $4]; }
	;

else
	:
		{ $$ = undefined; }
	| ELSE expr
		{ $$ = ["ELSE", $2]; }
	;
