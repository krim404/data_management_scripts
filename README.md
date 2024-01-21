# Data_Management_Scripts by Krim404
Here you'll find a curated collection of Bash scripts designed to streamline file and video management tasks, with a focus on seamless integration with the Linear Tape File System (LTFS). Whether you're a system administrator, content creator, or simply someone looking to automate and simplify your file-related processes, these scripts can be valuable tools in your arsenal.

## Scripts
Only a few hand picked scripts are explained here, the others are (at least in my mind) not really that important.

### ltfscp.sh
A simple script to copy only new files between a source folder and an LTFS target using ltfs_ordered_copy. This is meant to be used as a LTFS->LTFS copy tool to copy only new files to a tape as the original tool lacks a "skip if exists" flag.

### clean.sh
A script to check filenames of forbidden words and renames them recursively. Also includes a metadata check and overwrite feature.

## How to Use:
Each script in this repository will probably lack a good documentation but will do its job. These scripts are not meant to be used directly but more as a entrypoint

Feel free to contribute to this project by submitting pull requests, reporting issues, or suggesting improvements. Collaboration is encouraged to make these scripts even more powerful and user-friendly.
I hope you find these Bash scripts useful in your file and video management endeavors. Please star the repository if you find it helpful, and don't hesitate to reach out if you have any questions or suggestions. Happy scripting!
