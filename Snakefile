import os
from glob import glob

rule all:
    input:
        t1='bids/sub-01/anat/sub-01_T1w.nii',
        dwi='bids/sub-01/dwi',
        dd='bids/dataset_description.json'
        
rule untar:
    input:
        tar=lambda wildcards: glob('input/*.tar')[0]
    output:
        dicom_dir=temp(directory('dicoms'))
    shell:
        'mkdir -p {output.dicom_dir} && '
        "tar -xf {input.tar} --transform 's|.*/||'  -C {output.dicom_dir}"

checkpoint to_nifti:
    input:
        dicom_dir='dicoms'
    output:
        nifti_dir=temp(directory('niftis'))
    shell:
        'mkdir -p {output} && dcm2niix -i y -o {output}  {input} '

def get_t1_nii(wildcards):
    nifti_dir=checkpoints.to_nifti.get(**wildcards).output[0]
    
    #need to identify the T1w image - just glob for mprage for now
    t1w = glob(f'{nifti_dir}/*mprage*.nii')[0]
    return t1w
    

    
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
        
rule cp_t1:
    input:
        get_t1_nii
    output:
        t1='bids/sub-01/anat/sub-01_T1w.nii'
    shell:
        'cp {input} {output}'

rule cp_dd:
    input:
        'resources/dataset_description.json'
    output:
        'bids/dataset_description.json'
    shell:
        'cp {input} {output}'
    
