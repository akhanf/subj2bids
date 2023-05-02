import os
from glob import glob

rule all:
    input:
        t1='bids/sub-01/anat/sub-01_T1w.nii',
        dwi='bids/sub-01/dwi',
        dd='bids/dataset_description.json'


rule extract_archive:
    input:
        archive=config['in_archive']
    output:
        dicom_dir=temp(directory('dicoms'))
    script: 'scripts/extract_archive.py'

#zip of dicoms = extract and flatten, next step is to_nifti 
#zip of bids - extract as is, but will need to know what subject/session to process

checkpoint to_nifti:
    input:
        dicom_dir='dicoms'
    output:
        nifti_dir=temp(directory('niftis'))
    container:
        'docker://brainlife/dcm2niix:v1.0.20211006'
    shell:
        'mkdir -p {output} && dcm2niix -i y -o {output}  {input} '

   
rule cp_t1w_files:
    """this rule uses a list of possible matches to find the T1w nii"""
    input:
        nifti_dir='niftis'
    output: 
        t1='bids/sub-01/anat/sub-01_T1w.nii'
    script:
        'scripts/cp_t1w_file.py'
        
rule cp_dwi:
    input:
        nifti_dir='niftis'
    output:
        dwi_dir=directory('bids/sub-01/dwi')
    shell:
        "mkdir -p {output.dwi_dir} && i=1; "
        "for bvec in `ls {input.nifti_dir}/*.bvec`; "
        "do "
        "  prefix=${{bvec%.bvec}}; "
        "  cp -v ${{prefix}}.nii {output.dwi_dir}/sub-01_run-${{i}}_dwi.nii; "
        "  cp -v ${{prefix}}.bval {output.dwi_dir}/sub-01_run-${{i}}_dwi.bval; "
        "  cp -v ${{prefix}}.bvec {output.dwi_dir}/sub-01_run-${{i}}_dwi.bvec; "
        "  cp -v ${{prefix}}.json {output.dwi_dir}/sub-01_run-${{i}}_dwi.json; "
        "  i=$((i+1)); "
        "done "
        
rule cp_dd:
    input:
        'resources/dataset_description.json'
    output:
        'bids/dataset_description.json'
    shell:
        'cp {input} {output}'

"""   
rule run_diffparc:
    input:
        ' 

"""
