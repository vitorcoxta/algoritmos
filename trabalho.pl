use strict;
use Bio::Perl;
use Bio::Seq;
use Bio::SeqIO;
use Bio::Species;
use strict;
use warnings;
use DBI;

my ($Row,$SQL,$Select);

#DATABASE CONNECTION ON JOAO'S PC!
#my $dbh = DBI->connect('dbi:mysql:alg','root','blabla1') or die "Connection Error: $DBI::errstr\n";

#DATABASE CONNECTION ON VITOR'S PC!
my $dbh = DBI->connect('dbi:mysql:alg','root','5D311NC8') or die "Connection Error: $DBI::errstr\n";



#$SQL = "insert into tags(tag) values(\'Day1\');";

#my $SQL2 = "Delete from tags where tag='Day1' or tag='cenas';";

#my $update = $dbh->do($SQL2);


#if($update) {print ("Correu bem!!\n");}
#else {print ("JA fostes!!!\n");}


# $SQL= "select * from Temporario";

#$Select = $dbh->prepare($SQL2);
#$Select->execute();

#while($Row=$Select->fetchrow_hashref)
#{
 # print "$Row->{Nome} $Row->{Idade}";
#}

insertion();

sub insertion {
    my $option = interface("ask_insertion_type");
    if ($option == 1) {         #TODO: ver se faz sentido perguntar tanta coisa
        my $alphabet = interface("ask_alphabet");
        my $authority = interface("ask_authority");
        my $description = interface("ask_description");
        my $gene_name = interface("ask_gene_name");
        my $date = interface("ask_date");
        my $is_circular = interface("ask_is_circular");
        my @keywords = interface("ask_keywords");
        my $sequence = interface("ask_sequence");
        my $seq_version = interface("ask_seq_version");
        my $format = interface("ask_format");
        my $seq_length = length($sequence);
        
        #TODO: fazer para perguntar a especie e mete-la na tabela species
        #TODO: inserir as tags na tabela
        
        #print "\n\nAQUI ESTAO AS RESPOSTAS DADAS:\nalphabet: $alphabet\nauthority: $authority\ndesc: $description\ngene name: $gene_name\ndate: $date\ncircular: $is_circular\nkeywords: ";
        #for my $key (@keywords){
        #    print "$key, ";
        #}
        #print"\nsequence: $sequence\nseq_version: $seq_version\nformat: $format\n";#species: ".$species->species;
        
        #my $seq_obj = Bio::Seq->new(-seq => $sequence, -alphabet => $alphabet, -authority => $authority, -desc => $description, -display_id => $id, -get_dates => @dates, -is_circular => $is_circular, -keywords => @keywords, -seq_version => $seq_version);#, -species => $species);
        #my $seqio_obj = Bio::SeqIO->new(-file => '>sequence.gb', -format => 'genbank' );
        #$seqio_obj->write_seq($seq_obj);

        my $sql = "INSERT INTO sequences (alphabet, authority, description, gene_name, date, is_circular, length, format, seq_version) VALUES ('"
                  .$alphabet."', '".$authority."', '".$description."', '".$gene_name."', '".$date."', '".$is_circular."', '$seq_length', '".$format.
                  "', '".$seq_version."')";
        my $update = $dbh->do($sql);
        if($update) {print ("A insercao foi executada com sucesso\n");}
        else {print ("Ocorreu um erro na insercao\n");}
    }
    elsif ($option == 2) {print "queres num ficheiro. depois trato de ti\n"}
}

#This function will have ALL the interface things
sub interface {
    my ($type) = @_;
    my ($option, $answer);
    my @answer;
    if ($type eq "ask_insertion_type"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Do you want to insert the sequence manually, or is the sequence on a file?\n1 - Manually\n2 - In a file\n3 - Go back\n"; #TODO: go back. in the mean time, it is considered an invalid option
        $option = <>;
        if ($option == 1 or $option == 2) {return $option;}
        else {interface("ask_insertion_type_invalid_option");}
    }
    elsif($type eq "ask_insertion_type_invalid_option"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "INVALID OPTION! Please choose a valid one!\n\nDo you want to insert the sequence manually, or is the sequence on a file?\n1 - Manually\n2 - In a file\n3 - Go back\n"; #TODO: go back. in the mean time, it is considered an invalid option
        $option = <>;
        if ($option == 1 or $option == 2) {return $option;}
        else {interface("ask_insertion_type_invalid_option");}
    }
    elsif($type eq "ask_alphabet"){
        system $^O eq 'MSWin32' ? 'cls' : 'clear';
        print "Insert the alphabet: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_authority"){
        print "Insert the authority: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_description"){
        print "Insert the description: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_gene_name"){
        print "Insert the gene name: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_date"){
        print "Insert the date: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_is_circular"){
        print "Is it circular? [yes/no]: ";
        $answer = <>;
        chomp $answer;
        if ($answer eq "yes") {
            $answer = 1;
            return $answer;
        }
        elsif ($answer eq "no") {
            $answer = 0;
            return $answer;
        }
        else{
            print "INVALID OPTION! Please choose a valid one! ";
            interface("ask_is_circular");
        }
    }
    elsif($type eq "ask_keywords"){
        print "Insert the keywords (seperated by ','): ";
        $answer = <>;
        chomp $answer;
        @answer = split /\s*,\s*/, $answer;
        return @answer;
    }
    elsif($type eq "ask_sequence"){
        print "Insert the sequence: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_seq_version"){
        print "Insert the version of this sequence: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_species"){
        print "Insert the species (seperated by ','): ";
        $answer = <>;
        chomp $answer;
        @answer = split /\s*,\s*/, $answer;
        return @answer;
    }
    elsif($type eq "ask_format"){
        print "Insert the format [fasta/genbank/swiss]: ";
        $answer = <>;
        chomp $answer;
        if ($answer eq "fasta" or $answer eq "genbank" or $answer eq "swiss") {
            return $answer;
        }
        else{
            print "FORMAT NOT SUPORTED! Please choose a suported one! ";
            interface("ask_format");
        }
    }
}













