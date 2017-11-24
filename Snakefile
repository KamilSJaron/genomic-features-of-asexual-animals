# from snakemake.remote.NCBI import RemoteProvider as NCBIRemoteProvider
# NCBI = NCBIRemoteProvider(email="kamiljaron+ncbi@gmail.com") # email required by NCBI to prevent abuse
# import numpy

# species_with_genomes = [recrord['code'] for record in csv.DiscReader('download_table.tsv') if record['genome'] != 'NA']
# species_with_reads = [recrord['code'] for record in csv.DiscReader('download_table.tsv') if record['reads'] != 'NA']
species_with_genomes='Cbir1 Avag1 Fcan1 Lcla1 Dcor1 Dpac1 Minc1 Minc2 Mjav1 Mare1 Mflo1 Dpul1'.split(' ')
species_with_reads='Cbir1 Avag1 Fcan1 Lcla1 Dcor1 Minc3 Mjav2 Mare2 Mflo1 Mflo2 Ment1 Hduj1'.split(' ')
### TEMP Hduj1 kicked out (treated separately)

# kicked out :
# Dpac -> not available reads in SRA
# Pdav Psp62 Psp79 -> not available (yet?)
# Pant -> not published
# to be added
# Dpul


all_samples = list(set(species_with_genomes + species_with_reads))
all_species = list(set(map(lambda x: x[0:4], all_samples)))

mapping_files = []
# iterate though all species
for spec in all_species :
	# iterate though all references of that species
	for ref in [x for x in species_with_genomes if x.startswith(spec)]:
		# iterate though all samples with reads given species
		for samp in [x for x in species_with_reads if x.startswith(spec)]:
			mapping_file = 'data/' + samp + '/map_to_' + ref + '_marked.bam'
			mapping_files.append(mapping_file)



# ## help : print this help
# rule help :
# 	shell :
# 		"sed -n 's/^##//p' Snakefile"

rule map_all :
	input : mapping_files

rule download_all :
	input :
		expand("data/{sp}/genome.fa.gz", sp=species_with_genomes),
		expand("data/{sp}/reads_R1.fq.gz", sp=species_with_reads)

rule download_genome :
	threads : 1
	resources : mem=2000000, tmp=3000
	output : "data/{sp}/genome.fa.gz"
	shell : "scripts/cluster.sh scripts/download_genome.sh {wildcards.sp} tables/download_table.tsv {output}"

rule downlaod_reads :
	threads : 1
	resources : mem=2000000, tmp=30000
	output : "data/{sp}/reads_R1.fq.gz"
	shell : "scripts/cluster.sh scripts/download_reads.sh {wildcards.sp} tables/download_table.tsv data/{wildcards.sp}/reads_R"

rule index_reference :
	threads : 1
	resources : mem=20000000, tmp=10000
	input : "data/{reference}/genome.fa.gz"
	output : "data/{reference}/genome.fa.gz.bwt"
	shell :
		"scripts/cluster.sh scripts/index_genome.sh {input} data/{wildcards.reference}/genome.fa.gz."

rule map_reads :
	threads : 16
	resources : mem=104857600, tmp=40000
	input : "data/{reference}/genome.fa.gz.bwt", "data/{sample}/reads_R1.fq.gz"
	output : "data/{sample}/map_to_{reference}.bam"
	shell :
		"scripts/cluster.sh scripts/map_reads.sh {wildcards.sample} {wildcards.reference} data/{wildcards.sample}/reads_R[1,2].fq.gz data/{wildcards.reference}/genome.fa.gz.* {output}"

rule mark_duplicates :
	threads : 2
	resources : mem=20000000, tmp=40000
	input : "data/{sample}/map_to_{reference}.bam"
	output : "data/{sample}/map_to_{reference}_marked.bam"
	shell :
		"scripts/cluster.sh scripts/mark_dupl.sh {input} {output}"

# rule estimate_theta :
# 	threads : 1
# 	resources : mem=20000000, tmp=40000
# 	input : "data/{sample}/map_to_{reference}.bam"
# 	output : "data/{sample}/{reference}_w{window_size}_theta_estimates.txt"
# 	shell :
# 		"scripts/cluster.sh scripts/est_theta.sh {wildcards.sample} {wildcards.reference} {wildcards.window_size} {input} {output}"
