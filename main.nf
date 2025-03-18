#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// include non-process modules
include { help_message; version_message; complete_message; error_message; pipeline_start_message } from './modules/messages.nf'
include { default_params; check_params } from './modules/params_parser.nf'
include { help_or_version } from './modules/params_utilities.nf'

version = '1.0dev'

// setup default params
default_params = default_params()
// merge defaults with user params
merged_params = default_params + params

// help and version messages
help_or_version(merged_params, version)
final_params = check_params(merged_params)
// starting pipeline
pipeline_start_message(version, final_params)

// include processes
include { CHECKM2_PREDICT } from './modules/processes.nf' addParams(final_params)

workflow  {

	   assemblies_ch = channel
                          .fromPath( final_params.assemblies, checkIfExists: true )
                          .map { file -> tuple(file.baseName, file) }
			  .ifEmpty { error "Cannot find any assemblies matching: ${final_params.assemblies}" }
	   
	  
	   CHECKM2_PREDICT(assemblies_ch, final_params.db)
	   
	   combined_quality_report_ch = CHECKM2_PREDICT.out.checkm2_tsv_ch
	   			.map { meta, file -> file.readLines() }
				.collect()
				.map { lines ->
					def header = lines[0]
					def data = lines.flatten().findAll { it != header }
					(header + "\n") + data.sort().join("\n")
				//	(header + "\n")
				}
				.unique()
				
	// combined_quality_report_ch.view()			
	   combined_quality_report_ch
	   //	.view { "Combined results:\n$it" }
	   	.collectFile(name: 'combined_quality_report.tsv', storeDir: "${final_params.output_dir}")
	   
}

workflow.onComplete {
    complete_message(final_params, workflow, version)
}

workflow.onError {
    error_message(workflow)
}
