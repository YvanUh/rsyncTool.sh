# Project Title

Rsynctool.sh

### Prerequisites

GNU bash >= version 5.0.2(1)-release

### Usage

Just `bash rsynctool.sh`

## How it works

1. Asks for source and destination
2. Synchronize from source to destination
  * Show timestamp of last transfer
  * Append `rsyncProgress.txt` and `rsyncErrors.txt`
3. Verify the transfer
  * Append `rsyncVerification.txt`

## Acknowledgments

* Update option
This program does not backup, it synchronizes.
Existing files in the destination directory will therefore be replaced if
different size or newer.

* Timestamp
If the timestamp is blocked, one can look in `rsyncProgress.txt` to determine
if the script is blocked.

* Verification
If `rsyncVerification.txt` shows disparity between source and destination,
one should look at `rsyncErrors.txt`.
