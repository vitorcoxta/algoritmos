use Bio::Perl;
use Bio::Seq;
use Bio::SeqIO;
use strict;
use warnings;
use DBI;

my ($Row,$SQL,$Select);

my $dbh = DBI->connect('dbi:mysql:alg','root','blabla1') or die "Connection Error: $DBI::errstr\n";

#$SQL = "insert into tags(tag) values(\'Day1\');";

my $SQL2 = "Delete from tags where tag='Day1' or tag='cenas';";

my $update = $dbh->do($SQL2);


if($update) {print ("Correu bem!!\n");}
else {print ("JA fostes!!!\n");}


# $SQL= "select * from Temporario";

#$Select = $dbh->prepare($SQL2);
#$Select->execute();

#while($Row=$Select->fetchrow_hashref)
#{
 # print "$Row->{Nome} $Row->{Idade}";
#}


