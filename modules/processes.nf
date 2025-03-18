process CHECKM2_PREDICT {
    tag "$meta"
    publishDir "${params.output_dir}", mode:'copy'

    errorStrategy { task.attempt <= 2 ? "retry" : "ignore" }
    maxRetries 5
    
    conda "${projectDir}/conda_environments/checkm2.yml"
    
    input:
    tuple val(meta), path(fasta)
    path db

    output:
    tuple val(meta), path("${meta}")                , emit: output_ch
    tuple val(meta), path("${meta}/${meta}_checkm2_report.tsv"), emit: checkm2_tsv_ch
    path  "versions.yml"                      , emit: versions_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    
    checkm2 predict --input ${fasta} --output-directory ${meta} --threads 1 --database_path ${db}
    
    cp ${meta}/quality_report.tsv ${meta}/${meta}_checkm2_report.tsv
    
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        checkm2: \$(checkm2 --version)
    END_VERSIONS
    """
}
