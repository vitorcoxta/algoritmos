use strict;
use Bio::Perl;
use Bio::Seq;
use Bio::SeqIO;
use Bio::Species;
use strict;
use warnings;
use DBI();
use DBD::mysql;
use Bio::Root::Exception;
use Error qw(:try);

#------------------------DATABASE CONNECTIONS ON JOAO'S PC!-----------------------------
#my $dbh = DBI->connect('dbi:mysql:alg','root','blabla1') or die "Connection Error: $DBI::errstr\n";
#my %dbm_seq;
#dbmopen(%dbm_seq, 'METER AQUI O CAMINHO DESEJADO PARA A LOCALIZACAO DA HASH COM AS SEQUENCIAS', 0666);

#------------------------DATABASE CONNECTIONS ON VITOR'S PC!----------------------------
my $dbh = DBI->connect('dbi:mysql:alg','root','5D311NC8') or die "Connection Error: $DBI::errstr\n";
my %dbm_seq;
dbmopen(%dbm_seq, '/home/cof91/Documents/Mestrado/1º ano/1º semestre/Bioinformática - Ciências Biológicas/Algoritmos e Tecnologias da Bioinformática/Trabalho/algoritmos/database/sequences', 0666);

#------------------------DATABASE CONNECTIONS ON JOSE'S PC!----------------------------
#my $dbh = DBI->connect('dbi:mysql:alg','root','') or die "Connection Error: $DBI::errstr\n";
#my %dbm_seq;
#dbmopen(%dbm_seq, 'METER AQUI O CAMINHO DESEJADO PARA A LOCALIZACAO DA HASH COM AS SEQUENCIAS', 0666);

#TODO: Quando a interface estiver terminada, meter na opcao "sair" o close da connection às base de dados (close $dbh e dbmclose($dmb_seq))

main();

sub main{
    my $option = interface("welcome", 1, 0);
    if($option == 1){insertion();}
    elsif($option == 2){removal();}
    elsif($option == 3){change();}
    elsif($option == 9){interface("exit");}
}

#-----------------------This funtion inserts a sequence in the database: manually, from a file or from a remote database----------------------
sub insertion {
    my $option = interface("ask_insertion_type", 1, 0);
    if($option == 1) {
        #----------Asks user for useful information---------------
        my $authority = interface("ask_authority",1);
        my $alphabet = interface("ask_alphabet", 0);
        my $description = interface("ask_description", 0);
        my $gene_name = interface("ask_gene_name", 0);
        my $date = interface("ask_date", 0);
        my $is_circular = interface("ask_is_circular", 0);
        my @keywords = interface("ask_keywords", 0);
        my $sequence = interface("ask_sequence", 0);
        my $seq_version = interface("ask_seq_version", 0);
        my $specie = interface("ask_specie", 0);
        my $format = interface("ask_format", 0);
        my $seq_length = length($sequence);
        
        #print "\n\nAQUI ESTAO AS RESPOSTAS DADAS:\nalphabet: $alphabet\nauthority: $authority\ndesc: $description\ngene name: $gene_name\ndate: $date\ncircular: $is_circular\nkeywords: ";
        #for my $key (@keywords){
        #    print "$key, ";
        #}
        #print"\nsequence: $sequence\nseq_version: $seq_version\nformat: $format\n";#species: ".$species->species;
        
        insert_specie($specie);
        insert_sequence_db($specie, $alphabet, $authority, $description, $gene_name, $date, $is_circular, $seq_length, $format, $seq_version, "gene_name");
        my $id_sequence = insert_tags(@keywords);
        insert_sequence($id_sequence, $sequence);
    }
    elsif($option == 2) {
        #----------Gets useful information from the file or asks to user if the file doesn't have it---------------
        my ($path, $seqio);
        my $clear = 1;
        do{
            $path = interface("ask_file_path", $clear);
            try{
                $seqio = Bio::SeqIO->new(-file => $path);
            } catch Bio::Root::Exception with {$clear = 0};
        } while(!$seqio);
        my $format ;
        if((substr ($path, -5)) eq "fasta") {$format = "fasta";}
        elsif((substr ($path, -5)) eq "swiss") {$format = "swiss";}
        elsif((substr ($path, -2)) eq "gb") {$format = "genbank";}
        else {$format = interface("ask_format", 0);}
        my $seq = $seqio->next_seq;
        my $alphabet = interface("ask_alphabet", 0);                       #Asks the alphabet
        my $authority = $seq->authority;
        my $description = $seq->desc;
        my $accession_number = $seq->display_id;                     #This method returns the gene name
        my $is_circular;
        if($seq->is_circular) {$is_circular = 1;}
        else {$is_circular = 0;}
        my @keywords = interface("ask_keywords", 0);
        my $sequence = $seq->seq;
        my $seq_version;
        my $date;
        if($format eq "genbank" or $format eq "swiss"){
            $seq_version = $seq->seq_version;
            $date= ($seq->get_dates)[0];
        }
        else{
            $seq_version = interface("ask_seq_version", 0);
            $date= interface("ask_date", 0);
        }
        my $specie = interface("ask_specie", 0);               #Just to ask if the user wants to associate the sequence to any specie
        my $seq_length = $seq->length;
        
        #print "\n\nAQUI ESTAO AS RESPOSTAS DADAS:\nalphabet: $alphabet\nauthority: $authority\ndesc: $description\ngene name: $gene_name\ndate: $date\ncircular: $is_circular\nkeywords: ";
        #for my $key (@keywords){
        #    print "$key, ";
        #}
        #print"\nsequence: $sequence\nseq_version: $seq_version\nformat: $format\nspecies: $specie\n";
        insert_specie($specie);
        insert_sequence_db($specie, $alphabet, $authority, $description, $accession_number, $date, $is_circular, $seq_length, $format, $seq_version, "accession_number");
        my $id_sequence = insert_tags(@keywords);
        insert_sequence($id_sequence, $sequence);
    }
    elsif($option == 3){
        main();
    }
}





#-----------------Verifies if the inserted specie already exists on database. If it already exists, doesn't try to insert it---------------
sub insert_specie{
    my ($specie) = @_;
    my ($row, $id_sequence);
    my $sql = "SELECT id_specie FROM species WHERE specie='".$specie."'";
    my $result = $dbh->prepare($sql);
    $result->execute();
    if(!($result->fetchrow_hashref())){
        $sql = "INSERT INTO species (specie) VALUES ('".$specie."')";
        $dbh->do($sql);
    }
}






#-------------------Insert the sequence----------------------
        #Ineficiente porque faz o mesmo select 2 vezes, mas assim funciona... Deve ser porque nao pode fazer o fecthrow 2 vezes seguidas,
        #por isso tive de voltar a fazer o select...
        
        #The last argument tells ifit has the accession number (insertion from a file or from a remote DB) or the gene name (manual insertion)
sub insert_sequence_db{
    my ($specie, $alphabet, $authority, $description, $gene_name_or_accession_number, $date, $is_circular, $seq_length, $format, $seq_version, $type) = @_;
    my $sql = "SELECT id_specie FROM species WHERE specie='".$specie."'";
    my $result = $dbh->prepare($sql);
    $result->execute();
    while(my $row = $result->fetchrow_hashref()){
        if($type eq "gene_name") {
            $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, gene_name, date, is_circular, length, format, seq_version)"
            ."VALUES ('".$row->{'id_specie'}."', '".$alphabet."', '".$authority."', '".$description."', '".$gene_name_or_accession_number."', '".$date."', '"
            .$is_circular."', '$seq_length', '".$format."', '".$seq_version."')";
        }
        elsif($type eq "accession_number"){
            $sql = "INSERT INTO sequences (id_specie, alphabet, authority, description, accession_number, date, is_circular, length, format, seq_version)"
            ."VALUES ('".$row->{'id_specie'}."', '".$alphabet."', '".$authority."', '".$description."', '".$gene_name_or_accession_number."', '".$date."', '"
            .$is_circular."', '$seq_length', '".$format."', '".$seq_version."')";
        }
        $dbh->do($sql);
    }
}





#-------------------Insert the tags and returns the $id_sequence------------------------------
sub insert_tags{
    my (@keywords) = @_;
    my $id_sequence;
    my $sql = "SELECT LAST_INSERT_ID()";
    my $result = $dbh->prepare($sql);
    $result->execute();
    while(my $row = $result->fetchrow_hashref()){
        $id_sequence = $row->{'LAST_INSERT_ID()'};
    }
    
    for my $keyword (@keywords){
        #-------------Verifies if the inserted tags already exist on database. If they already exist, doesn't try to insert them-----------
        $sql = "SELECT id_tag FROM tags WHERE tag='".$keyword."'";
        $result = $dbh->prepare($sql);
        $result->execute();
        if(!($result->fetchrow_hashref())){
            $sql = "INSERT INTO tags (tag) VALUES ('".$keyword."')";
            $dbh->do($sql);
        }
        
        $sql = "SELECT id_tag FROM tags WHERE tag='".$keyword."'";
        $result = $dbh->prepare($sql);
        $result->execute();
        
        #--------------Insert the tuple id_sequence - id_tag on seq_tags table------------------------
        while(my $row = $result->fetchrow_hashref()){
            $sql = "INSERT INTO seq_tags (id_sequence, id_tag) VALUES ('".$id_sequence."', '".$row->{'id_tag'}."')";
            $dbh->do($sql);#my $result2 = 
            #if($result2) {print ("A insercao foi executada com sucesso\n");}
            #else {print ("Ocorreu um erro na insercao\n");}
        }
    }
    return $id_sequence;
}






#----------------Insert the sequence on a DBM----------------------------------------
sub insert_sequence{
    my ($id_sequence, $sequence) = @_;
    $dbm_seq{$id_sequence} = $sequence;
    print "A insercao foi executada com sucesso\n";             #TODO: depois de a interface estar pronta, ver se sera preciso isto
}





#--------------------This function indicates the right path to remove data from the database, depending from the user's decision------------------------------------
sub removal{
    my $option = interface("ask_removal_type", 1, 0);
    if($option == 1){
        my $accession_number = interface("ask_accession_number", 1);
        remove($accession_number, "accession_number");
    }
    elsif($option == 2){
        my $gene_name = interface("ask_gene_name", 1);
        remove($gene_name, "gene_name");
    }
    elsif($option == 3){
        main();
    }
}




#-------------------This function deletes a sequence from the database
sub remove{
    my ($accession_number_or_gene_name, $type) = @_;
    my $sql;
    if($type eq "accession_number"){$sql = "SELECT id_sequence FROM sequences WHERE accession_number='".$accession_number_or_gene_name."'";}
    elsif($type eq "gene_name"){$sql = "SELECT id_sequence FROM sequences WHERE gene_name='".$accession_number_or_gene_name."'";}
    my $result = $dbh->prepare($sql);
    $result->execute();
    while(my $row = $result->fetchrow_hashref()){
        delete $dbm_seq{$row->{'id_sequence'}};             #Deletes the sequence from the Hash Table dbm_seq
        remove_seq_tags($row->{'id_sequence'});
    }
    if($type eq "accession_number"){$sql = "DELETE FROM sequences WHERE accession_number='".$accession_number_or_gene_name."'";}
    elsif($type eq "gene_name"){$sql = "DELETE FROM sequences WHERE gene_name='".$accession_number_or_gene_name."'";}
    $dbh->do($sql);
}




#-----------------------This funtion will remove data from the table seq_tags------------------------------
sub remove_seq_tags{
    my ($id_sequence) = @_;
    my $sql = "DELETE FROM seq_tags WHERE id_sequence = '".$id_sequence."'";
    $dbh->do($sql);
}


sub change{
    
}





#------------------This function will have ALL the interface things-------------------
sub interface {
    my ($type, $clear, $invalid) = @_;
    my ($option, $answer);
    my @answer;
    if($type eq "welcome"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n"}
        else {print "\t\t\tWELCOME TO CENASSAS. ALGUEM QUE ESCREVA ALGO AQUI, QUE TOU SEM IDEIAS!\n\n";}
        print "What do you want to do?\n\n1 - Insertion of a sequence\n2 - Removal of a sequence\n3 - Change a sequence\n\n9 - Exit\n";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 3 or $option == 9) {return $option;}
        else {interface("welcome", 1, 1);}
    }
    elsif($type eq "ask_insertion_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "Do you want to insert the sequence manually, or is the sequence on a file?\n\n1 - Manually\n2 - In a file\n3 - Go back\n\n";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 3) {return $option;}
        else {interface("ask_insertion_type", 1, 1);}
    }
    elsif($type eq "ask_authority"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the authority: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_alphabet"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the alphabet: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_description"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the description: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_gene_name"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the gene name: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_date"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the date: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_is_circular"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Is it circular? [yes/no]: ";
        $answer = <>;
        chomp $answer;
        if($answer eq "yes") {
            $answer = 1;
            return $answer;
        }
        elsif($answer eq "no") {
            $answer = 0;
            return $answer;
        }
        else{
            print "INVALID OPTION! Please choose a valid one! ";
            interface("ask_is_circular", 0);
        }
    }
    elsif($type eq "ask_keywords"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the keywords (seperated by ','): ";
        $answer = <>;
        chomp $answer;
        @answer = split /\s*,\s*/, $answer;
        return @answer;
    }
    elsif($type eq "ask_sequence"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the sequence: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_seq_version"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the version of this sequence: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_specie"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the specie: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_format"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the format [fasta/genbank/swiss]: ";
        $answer = <>;
        chomp $answer;
        if($answer eq "fasta" or $answer eq "genbank" or $answer eq "swiss") {
            return $answer;
        }
        else{
            print "FORMAT NOT SUPORTED! Please choose a suported one! ";
            interface("ask_format", 0);
        }
    }
    elsif($type eq "ask_file_path"){
        if($clear) {
            system $^O eq 'MSWin32' ? 'cls' : 'clear';
            print "Insert the file path: ";
        }
        else {print "FILE NOT FOUND! Insert a valid file path: ";}
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "ask_removal_type"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        if($invalid) {print "INVALID OPTION! Please choose a valid one!\n\n";}
        print "Choose a way to remove the sequence:\n\n1 - By an accession number\n2 - By a gene name\n3 - Go back\n\n";
        $option = <>;
        if($option == 1 or $option == 2 or $option == 3) {return $option;}
        else {interface("ask_removal_type",1, 1);}
    }
    elsif($type eq "ask_accession_number"){
        if($clear) {system $^O eq 'MSWin32' ? 'cls' : 'clear';}
        print "Insert the accession number: ";
        $answer = <>;
        chomp $answer;
        return $answer;
    }
    elsif($type eq "exit"){
        print "METER AQUI AS CENAS DE DESPEDIDA DO JOAO. XAU AI!\n\n";
    }
}













