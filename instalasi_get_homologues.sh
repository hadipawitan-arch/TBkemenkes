#!/bin/bash
# Cek apakah environment get_homologues sudah dibuat
# Environment target
ENV_NAME="get_homologues"

echo "Cek apakah environment $ENV_NAME sudah dibuat"

if conda env list | grep -q -E "^${ENV_NAME}\s"; then
    # The environment exists, so we can use it
    echo "Environment $ENV_NAME sudah dibuat."
    
    # Run a command *inside* the environment using 'conda run'
    echo "Running 'get_homologues.pl --version' pada $ENV_NAME..."
    conda run -n $ENV_NAME get_homologues.pl -v
    
else
    # The environment does not exist
    echo "Error: Environment '$ENV_NAME' tidak ditemukan."
    echo "Akan membuat environment baru"
    read -p "Apakah ingin membuat environment dan instalasi sekarang? (y/n) " -n 1 -r
   
	# 2. Add a newline for cleaner output
    echo    # (moves to the next line)

	# 3. Check the user's reply
	#    We check if the $REPLY variable starts with 'y' or 'Y'.
    if [[ $REPLY =~ ^[Yy]$ ]]; then
    
    	# 4. If yes, run the installation commands
    	echo "Memulai instalasi $ENV_NAME"
    
    # Environment and instalation of get_homologues
	conda create -n $ENV_NAME -c conda-forge -c bioconda $ENV_NAME -y
    
	echo "Instalasi $ENV_NAME selesai"
    	echo "---"
    	echo "Untuk menyalakan environment"
    	echo "conda activate $ENV_NAME"
    
    else
    	# 5. If no
    	echo "Instalasi tidak dilakukan"
    fi
fi

