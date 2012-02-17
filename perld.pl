=head1 MAIN

This is the main funtion of this software. This function indicates the right path according to what the users wants to do.

B<USAGE:>
main($clear);

The argument that it receives is a flag to tell if it is suppose or not to clear the screen.


=head1 DATABASE_OPERATIONS

This funtion will call the functions that operate with the database.


=head1 BIOINFORMATICS_OPERATIONS

This function just calls the right funtions to perform a bioinformatics job.

B<USAGE:>
bioinformatics_operations();


=head1 INSERTION

This funtion inserts a sequence in the database: manually, from a file or from a remote database.

B<USAGE:>
insertion();


=head1 GET_FORMAT

This function is capable of obtain the format of a file.

B<USAGE:>
get_format($path);

The argument that it receives is the filename/path to the file.

B<RETURNS:>
The file format.


=head1 GET_ID_SEQUENCE

This function will get the id of the sequence in the database.

B<USAGE:>
get_id_sequence($acc_or_name, $type);

The arguments are:

=over 12

=item - $acc_or_name:

string with the accession number or with the gene name (depending if the sequence has an accession number or a gene name);
 
=item - $type:

string that tells if the previous argument is an accession number (and it has the value "accession_number") or a gene name (and it has the value "gene_name").

=back

B<RETURNS:>
The id of the sequence (auto incremented id from the database).


=head1 INSERT_SPECIE

This function verifies if the inserted specie already exists on database. If it already exists, doesn't try to insert it.

B<USAGE:>
insert_specie($specie);

The argument is a string with the specie to insert on the database.


=head1 INSERT_SEQUENCE_DB

This function inserts the sequence informations into the database.

B<USAGE:>
insert_sequence_db($specie, $alphabet, $authority, $description, $gene_name, $date, $is_circular, $seq_length, $format, $seq_version, $accession_number);

The arguments are:

=over 12

=item - $specie:
 
string with the specie;

=item - $alphabet:

string with the alphabet of the sequence ("dna", "rna" or "protein");

=item - $authority:

string with the authority of the sequence;

=item - $description:

string with the description of the sequence;

=item - $gene_name:

string with the gene name;
 
=item - $date:

string with the date;
 
=item - $is_circular:
 
boolean to tell if the sequence is circular (1) or not (0);
 
=item - $seq_length:
 
int with the length of the sequence;
 
=item - $format:

string with the format of the sequence ("fasta", "genbank" or "swiss");
 
=item - $seq_version:

string with the version of the sequence;
 
=item - $accession_number:

string with the accession number of the sequence.

=back


=head1 INSERT_TAGS

This function inserts the tags on the database, and returns id of the sequence (id auto incremented on the database).

B<USAGE:>
insert_tags($flag, @keywords);

The arguments that this function receives are:

=over 12

=item - $flag:

boolean to teel if the user wants to add keywords or not;
 
=item - @keywords:

list of strings, that are the key_words;

=back

B<RETURNS:>
The id of the sequence (id auto incremented on the database).


=head1 INSERT_SEQUENCE

This function inserts the sequence on a DBM hash.

B<USAGE:>
insert_sequence($id_sequence, $seq, $format, $with_accession);

The arguments are:

=over 12

=item - $id_sequence:

int with the id of the sequence (id auto incremented on the database);
 
=item -  $seq:

Bio::Seq object, with the information aboout the sequence;
 
=item - $format:

string with the format of the sequence;
 
=item - $with_accession:

flag to tell if the sequence has an accession number (in other words, if it was inserted form a file or from a remote database, and in this case the sequence file name will have the accession number), or if it doesn't (in other words, if the sequence was inserted manually, and in this case the sequence file name will have the gene name).

=back


=head1 GENERIC_IMPORTATION

This funtion inserts the sequence from a remote database.

B<USAGE:>
generic_importation($db);

The argument is a string with the database where the sequence comes from.


=head1 REMOVAL

This function indicates the right path to remove data from the database, depending from the user's decision.

B<USAGE:>
removal();


=head1 REMOVE

This function deletes a sequence from the database and from the DBM hash (including from the folder 'sequences').

B<USAGE:>
remove($accession_number_or_gene_name, $type);

The arguments are:

=over 12

=item - $accession_number_or_gene_name:

string with the accession number or with the gene name (depending if the sequence has an accession number or a gene name);
 
=item - $type:

string that tells if the previous argument is an accession number (and it has the value "accession_number") or a gene name (and it has the value "gene_name").

=back


=head1 REMOVE_SEQ_TAGS

This funtion will remove data from the table seq_tags on the database.

B<USAGE:>
remove_seq_tags($id_sequence);

This funtion receives the id of the sequence on the database.


=head1 MODIFICATION

This function indicates the right path to modify data from the database, depending from the user's decision.

B<USAGE:>
modification();


=head1 MODIFY

This function modifies a sequence saved on the database.

B<USAGE:>
modify($accession_number_or_gene_name, $type);

The arguments are:

=over 12

=item - $accession_number_or_gene_name:

string with the accession number or with the gene name (depending if the sequence has an accession number or a gene name);
 
=item - $type:

string that tells if the previous argument is an accession number (and it has the value "accession_number") or a gene name (and it has the value "gene_name").

=back

B<RETURNS:>
An hash with the name of the files to be modified.


=head1 CREATE_FILE

This function creates the file where the user will modify the data.

B<USAGE:>
create_file($current, $total, $row);

The arguments are:

=over 12

=item - $current:

int that indicates the current file (e.g. 1 (current) in 3 (total) files);
 
=item - $total:

int that indicates the total of files to be modified;

=item - $row:

Reference to an hash with the data that comes from the database.

=back


=head1 FETCH_INFO

This funtion fetches the new information given by the user from the modified files.

B<USAGE:>
fetch_info($current, $total, $format);

The arguments are:

=over 12

=item - $current:

int that indicates the current file (e.g. 1 (current) in 3 (total) files);
 
=item - $total:

int that indicates the total of files to be modified;

=item - $row:

Reference to an hash with the data that comes from the database.

=back

B<RETURNS:>
A Bio::Seq object with the information from the file.


=head1 UPDATE_INFO

This funtion updates the info modified by the user in the database and the DBM hash.

B<USAGE:>
update_info($seq, $id_sequence);

The arguments are:

=over 12

=item - $seq:

Bio::Seq object with the information about the sequence;

=item - $id_sequence:

int with the id of the sequence from the database.

=back


=head1 DISPLAY_MODIFIED

This funtion displays the modified sequences table, and asks if the user want to see it on the program (with the 'pg' linux command).

B<USAGE:>
display_modified(%modified);

The argument is an hash with the names of the files that are going to be modified.


=head1 VERIFY_ACCESSION

This function verifies if the accession version already exists on the database.

B<USAGE:>
verify_accession($type, $with);

The arguments are:

=over 12

=item - $type:

string with the accession number or the accession version;

=item - $with:

string that says if it is to search by accession number AND accession version (and it has the value "with") or just to search by the accession number (and it has the value "wothout").

=back

B<RETURNS:>
A boolean that tells if the accession number already existis (1) or not (0).


=head1 COUNT_ACCESSION_OR_NAME

This function counts the number of sequences that have the same accession number or the same gene name.

B<USAGE:>
count_accession_or_name($accession_number_or_gene_name, $type);

The arguments are:

=over 12

=item - $accession_number_or_gene_name:

string with the accession number or with the gene name (depending if the sequence has an accession number or a gene name);
 
=item - $type:

string that tells if the previous argument is an accession number (and it has the value "accession_number") or a gene name (and it has the value "gene_name").

=back

B<RETURNS:>
int with the number of equals accession numbers or gene names.


=head1 VERIFY_ACCESSION_IN_FILE

This funtion verifies if the accession version already exists for the importation from a file.

B<USAGE:>
verify_accession_in_file($file);

The argument is the filename/path to the file.

B<RETURNS:>
A boolean that tells if the accession number already existis (1) or not (0).


=head1 VERIFY_GENE_NAME

This funtion verifies if the gene name already exists on the database.

B<USAGE:>
verify_gene_name($gene_name);

The argument is a string with the gene name.

B<RETURNS:>
A boolean that tells if the gene name already existis (1) or not (0).


=head1 INSERT_SPECIE_IMPORTATION

This function inserts the specie for the insertion from remote databases.

B<USAGE:>
insert_specie_importation($specie);

The argument is a string with the specie to be inserted.

B<RETURNS:>
The id of the sequence from the database.


=head1 INSERT_SEQUENCE_IMPORTATION

This function inserts the sequence for the insertion from remote databases.

B<USAGE:>
insert_sequence_importation($format,$id_specie,$seq,$version);

The arguments are:

=over 12

=item - $format:

string with the file format ("fasta", "genbank" or "swiss");
 
=item - $id_specie:

int with the id of the specie (id auto incremented on the database);

=item - $seq:

Bio::Seq object with the sequence information;
 
=item - $version:

flag that tells if the Bio::Seq has an accession version to be inserted (1) or not (0);

=back


=head1 DISPLAY_TAGS

This funtion displays in the screen a keywords table.

B<USAGE:>
display_tags();


=head1 DISPLAY_SPECIES

This funtion dysplays in the screen a species table.

B<USAGE:>
display_species();


=head1 VERIFY_VERSION

This funtion verifies if an accession version already exists.

B<USAGE:>
verify_version($version);

The argument is a string with the accession version already exists.

B<RETURNS:>
A boolean that tells if the accession version already exists (0) or not (1);


=head1 BLAST

This is the funtion that runs a remote blast. It can run a blastp, blastn, blastx, tblastn or tblastx.

B<USAGE:>
blast();


=head1 MOTIF

This funtion gets the motif and calls the right funtions to serch it on the sequences on the database.

B<USAGE:>
motif();


=head1 SEARCH_MOTIF

This function searches for a motif in all the sequences of the database.

B<USAGE:>
search_motif($motif);

The argument is a string with the motif (sequece) to be searched in all the sequences.

B<RETURNS:>
References for two hashes: one contains the sequences which the motif matches, and the other have a list with the positions where the motif was found for each sequence that had matched.


=head1 DISPLAY_MATCH

This funtion displays the match table and the positions where the motif was found, and asks if the user want to see it with the 'pg' linux command.

B<USAGE:>
display_match($match, $positions);

The arguments are:

=over 12

=item - $match:

Reference for an hash that has all the sequences where the motif was found;

=item - $positions:

Reference for an hash that has a list with all the positions where the motif was found for all the sequences in the hash before.

=back


=head1 STATISTICS

This funtion will get the important information from the sequences to get some statistic information.

B<USAGE:>
statistics();


=head1 GET_STATISTICS_INTO_FILE

This funtion writes statistics into a file, so the user can use it for whatever he wants.

B<USAGE:>
get_statistics_into_file($filename, $seq);

The arguments are:

=over 12

=item - $filename:

Reference for an hash that has all the sequences where the motif was found;

=item - $seq:

Reference for an hash that has a list with all the positions where the motif was found for all the sequences in the hash before.

=back








